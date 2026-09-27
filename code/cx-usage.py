#!/usr/bin/env python3
"""Local Codex usage dashboard. Costs are API-price equivalents, not plan charges."""

from __future__ import annotations

import argparse
import bisect
import json
import os
import select
import signal
import sys
import termios
import time
import tty
from collections import defaultdict
from dataclasses import dataclass
from datetime import date, datetime, timedelta, timezone
from pathlib import Path
from zoneinfo import ZoneInfo

try:
    from rich.align import Align
    from rich.columns import Columns
    from rich.console import Console, Group
    from rich.live import Live
    from rich.panel import Panel
    from rich.table import Table
    from rich.text import Text
except ImportError:
    sys.exit("Install the TUI dependency: python -m pip install rich")


# USD per million tokens, standard API processing, checked 2026-09-26.
# https://developers.openai.com/api/docs/pricing
PRICES = {
    "gpt-6-astra": (10.0, 1.0, 12.5, 50.0),
    "gpt-6-sol": (2.0, 0.2, 2.5, 10.0),
    "gpt-6-luna": (0.1, 0.01, 0.125, 0.5),
    "gpt-5.6-sol": (4.0, 0.4, 5.0, 20.0),
    "gpt-5.6-terra": (2.0, 0.2, 2.5, 12.0),
    "gpt-5.6-luna": (0.2, 0.02, 0.25, 1.2),
    "gpt-5.4-mini": (0.75, 0.075, 0.9375, 4.5),
}


@dataclass(frozen=True)
class Usage:
    at: datetime
    model: str
    input: int
    cached: int
    write: int
    output: int

    @property
    def cost(self) -> float | None:
        rates = PRICES.get(self.model)
        if rates is None:
            return None
        ordinary = max(0, self.input - self.cached - self.write)
        multiplier = 2 if self.model.startswith(("gpt-6-", "gpt-5.6-")) and self.input > 272_000 else 1
        output_multiplier = 1.5 if multiplier == 2 else 1
        return (ordinary * rates[0] * multiplier
                + self.cached * rates[1] * multiplier
                + self.write * rates[2] * multiplier
                + self.output * rates[3] * output_multiplier) / 1_000_000


def timestamp(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def usage_from(raw: dict, at: datetime, model: str) -> Usage:
    def amount(key: str) -> int:
        return max(0, int(raw.get(key) or 0))
    return Usage(at, model, amount("input_tokens"), amount("cached_input_tokens"),
                 amount("cache_write_input_tokens"), amount("output_tokens"))


def read_rollout(path: Path) -> tuple[list[Usage], list[tuple[datetime, dict]]]:
    records: list[Usage] = []
    fallback: list[Usage] = []
    limits = []
    model = "unknown"
    previous = {key: 0 for key in ("input_tokens", "cached_input_tokens",
                                    "cache_write_input_tokens", "output_tokens")}
    try:
        with path.open(encoding="utf-8", errors="replace") as lines:
            for line in lines:
                try:
                    event = json.loads(line)
                    at = timestamp(event["timestamp"])
                except (ValueError, KeyError, TypeError):
                    continue
                kind = event.get("type")
                payload = event.get("payload") or {}
                if kind == "turn_context":
                    model = payload.get("model") or model
                elif kind == "token_usage_record":
                    raw = payload.get("usage")
                    if isinstance(raw, dict):
                        records.append(usage_from(raw, at, model))
                elif kind == "event_msg" and payload.get("type") == "token_count":
                    if isinstance(payload.get("rate_limits"), dict):
                        limits.append((at, payload["rate_limits"]))
                    info = payload.get("info") or {}
                    total = info.get("total_token_usage")
                    if isinstance(total, dict):
                        keys = previous.keys()
                        current = {key: max(0, int(total.get(key) or 0)) for key in keys}
                        # A counter reset can occur within a rollout. Treat it as a new baseline.
                        delta = {key: current[key] - previous[key] if current[key] >= previous[key]
                                 else current[key] for key in keys}
                        previous = current
                        fallback.append(usage_from(delta, at, model))
    except (OSError, UnicodeError):
        pass
    # Newer rollouts contain both records and cumulative token_count events.
    return (records if records else fallback), limits


class RolloutStore:
    def __init__(self, root: Path) -> None:
        self.root = root
        self.files: dict[Path, tuple[int, int, list[Usage], list[tuple[datetime, dict]]]] = {}
        self.snapshot: tuple[list[Usage], dict[str, tuple[datetime, dict]],
                             list[tuple[datetime, dict]], int] | None = None

    def load(self) -> tuple[list[Usage], dict[str, tuple[datetime, dict]],
                            list[tuple[datetime, dict]], int]:
        paths: set[Path] = set()
        changed = self.snapshot is None
        for base in (self.root / "sessions", self.root / "archived_sessions"):
            if not base.exists():
                continue
            for path in base.rglob("*.jsonl"):
                paths.add(path)
                try:
                    stat = path.stat()
                except OSError:
                    continue
                cached = self.files.get(path)
                if cached is None or cached[:2] != (stat.st_mtime_ns, stat.st_size):
                    records, limits = read_rollout(path)
                    self.files[path] = (stat.st_mtime_ns, stat.st_size, records, limits)
                    changed = True
        if paths != self.files.keys():
            changed = True
            self.files = {path: value for path, value in self.files.items() if path in paths}
        if not changed:
            assert self.snapshot is not None
            return self.snapshot

        all_usage: list[Usage] = []
        latest: dict[str, tuple[datetime, dict]] = {}
        history: list[tuple[datetime, dict]] = []
        for _, _, records, limits in self.files.values():
            all_usage.extend(records)
            for at, rate in limits:
                limit_id = str(rate.get("limit_id") or "codex")
                if limit_id == "codex":
                    history.append((at, rate))
                if limit_id not in latest or at > latest[limit_id][0]:
                    latest[limit_id] = (at, rate)
        self.snapshot = all_usage, latest, history, len(paths)
        return self.snapshot


def money(value: float) -> str:
    return f"${value:,.4f}" if value < 1 else f"${value:,.2f}"


def compact(value: int) -> str:
    if value >= 1_000_000:
        return f"{value / 1_000_000:,.2f}M"
    if value >= 10_000:
        return f"{value / 1_000:,.1f}K"
    return f"{value:,}"


def summary(rows: list[Usage]) -> tuple[float, int, int, int, int, int]:
    total, inp, cached, writes, out, unknown = 0.0, 0, 0, 0, 0, 0
    for row in rows:
        cost = row.cost
        total += cost or 0
        inp += row.input
        cached += row.cached
        writes += row.write
        out += row.output
        unknown += cost is None
    return total, inp, cached, writes, out, unknown


def window_card(title: str, rows: list[Usage], limit: dict | None,
                zone: ZoneInfo, note: str, small: bool) -> Panel:
    total, inp, cached, writes, out, unknown = summary(rows)
    content: list = [Text(money(total), style="bold bright_cyan", justify="center")]
    if not small:
        content.append(Text("estimated API equivalent", style="dim", justify="center"))
    if limit:
        percent = float(limit.get("used_percent") or 0)
        end = datetime.fromtimestamp(int(limit["resets_at"]), timezone.utc).astimezone(zone)
        filled = round(min(100, percent) / 5)
        content.append(Text("━" * filled + "─" * (20 - filled),
                            style="bright_magenta", justify="center"))
        caption = (f"{percent:.1f}% used · reset {end:%d %b %H:%M}" if small else
                   f"Allowance {percent:.1f}%  ·  resets {end:%d %b %H:%M}")
        content.append(Text(caption,
                            justify="center"))
    else:
        content.append(Text("Codex limit snapshot unavailable", style="yellow", justify="center"))
    if small:
        content.append(Text(f"Input {compact(inp)} · cached {compact(cached)}",
                            style="dim", justify="center"))
        content.append(Text(f"Output {compact(out)} · write {compact(writes)}",
                            style="dim", justify="center"))
    else:
        content.append(Text(f"Input {compact(inp)}  ·  cached {compact(cached)}  ·  write {compact(writes)}  ·  output {compact(out)}",
                            style="dim", justify="center"))
    if unknown:
        content.append(Text(f"{unknown} unpriced response(s)", style="yellow", justify="center"))
    if not small:
        content.append(Text(note, style="dim", justify="center"))
    return Panel(Align.center(Group(*content), vertical="middle"), title=title,
                 border_style="cyan", padding=(1, 1))


def period_key(at: datetime, kind: str, zone: ZoneInfo):
    d = at.astimezone(zone).date()
    if kind == "day":
        return d
    if kind == "week":
        return d - timedelta(days=d.weekday())
    return d.replace(day=1)


def calendar_periods(rows: list[Usage], kind: str, zone: ZoneInfo) -> list[tuple[date, tuple]]:
    buckets: dict = defaultdict(lambda: [0.0, 0, 0, 0, 0, 0])
    for row in rows:
        total = buckets[period_key(row.at, kind, zone)]
        cost = row.cost
        total[0] += cost or 0
        total[1] += row.input
        total[2] += row.cached
        total[3] += row.write
        total[4] += row.output
        total[5] += cost is None
    return [(key, tuple(buckets[key])) for key in sorted(buckets, reverse=True)]


def period_table(periods: list[tuple], kind: str,
                 offset: int, page_size: int) -> tuple[Table, int]:
    table = Table(expand=True, box=None, header_style="bold magenta", show_edge=False,
                  row_styles=["", "dim"])
    table.add_column(kind.title(), ratio=2)
    table.add_column("USD est.", justify="right")
    table.add_column("Input", justify="right")
    table.add_column("Cached", justify="right")
    table.add_column("Output", justify="right")
    for key, (total, inp, cached, _, out, unknown) in periods[offset:offset + page_size]:
        label = key.strftime("%Y-%m-%d") if kind != "month" else key.strftime("%Y-%m")
        table.add_row(label + (" *" if unknown else ""), money(total), compact(inp),
                      compact(cached), compact(out))
    if not periods:
        table.add_row("No local usage", "—", "—", "—", "—")
    return table, max(0, len(periods) - page_size)


def capacity_periods(rows: list[Usage], history: list[tuple[datetime, dict]],
                     kind: str, zone: ZoneInfo) -> tuple[list[tuple], float]:
    """Show a proxy for quota size, inferred from local spend per percent used."""
    field = "primary" if kind == "limit5" else "secondary"
    minutes = 300 if kind == "limit5" else 10080
    snapshots = []
    for at, rate in history:
        window = rate.get(field) or {}
        if window.get("window_minutes") != minutes or not window.get("resets_at"):
            continue
        snapshots.append((int(window["resets_at"]), at,
                          float(window.get("used_percent") or 0)))
    snapshots.sort()
    groups: list[list[tuple[int, datetime, float]]] = []
    for item in snapshots:
        if not groups or item[0] - groups[-1][-1][0] > 60:
            groups.append([])
        groups[-1].append(item)

    priced = sorted(((row.at, cost) for row in rows
                     if (cost := row.cost) is not None), key=lambda item: item[0])
    dates = [at for at, _ in priced]
    running = [0.0]
    for _, cost in priced:
        running.append(running[-1] + cost)

    periods = []
    for group in groups:
        group.sort(key=lambda item: item[1])
        first, last = group[0], group[-1]
        gained = max(item[2] for item in group) - first[2]
        start_index = bisect.bisect_right(dates, first[1])
        end_index = bisect.bisect_right(dates, last[1])
        spent = running[end_index] - running[start_index]
        capacity = spent * 100 / gained if gained >= 20 and spent > 0 else None
        reset = datetime.fromtimestamp(max(item[0] for item in group), timezone.utc)
        start = reset - timedelta(minutes=minutes)
        periods.append((start.astimezone(zone), gained, capacity))
    periods.reverse()
    max_capacity = max((p[2] for p in periods if p[2] is not None), default=0)
    prior = None
    with_prior = []
    for at, gained, cap in reversed(periods):
        with_prior.append((at, gained, cap, prior))
        if cap is not None:
            prior = cap
    with_prior.reverse()
    return with_prior, max_capacity


def capacity_table(periods: list[tuple], max_capacity: float, kind: str,
                   offset: int, page_size: int) -> tuple[Table, int]:
    table = Table(expand=True, box=None, header_style="bold magenta",
                  row_styles=["", "dim"])
    table.add_column("Codex window", min_width=15)
    table.add_column("Cap proxy", justify="right", min_width=10)
    table.add_column("Trend", min_width=19)
    table.add_column("Observed", justify="right", min_width=10)
    table.add_column("vs prior", justify="right", min_width=9)
    for index in range(offset, min(len(periods), offset + page_size)):
        at, gained, cap, prior = periods[index]
        label = at.strftime("%y-%m-%d %H:%M") if kind == "limit5" else at.strftime("%y-%m-%d")
        if cap is None:
            table.add_row(label, "—", "", f"{gained:.0f} pp", "—")
            continue
        width = max(1, round(cap / max_capacity * 16)) if max_capacity else 0
        bar = Text("█" * width, style="cyan")
        change = f"{(cap / prior - 1) * 100:+.0f}%" if prior else "—"
        table.add_row(label, money(cap), bar, f"{gained:.0f} pp", change)
    if not periods:
        table.add_row("No snapshots", "—", "", "—", "—")
    return table, max(0, len(periods) - page_size)


class Dashboard:
    def __init__(self, snapshot: tuple, zone: ZoneInfo) -> None:
        self.rows, self.latest, self.history, self.files = snapshot
        self.zone = zone
        self.calendar: dict[str, list[tuple]] = {}
        self.capacity: dict[str, tuple[list[tuple], float]] = {}
        self.cards_cache: dict[bool, list[Panel]] = {}

    def periods(self, kind: str) -> list[tuple]:
        if kind in ("limit5", "limit7"):
            if kind not in self.capacity:
                self.capacity[kind] = capacity_periods(
                    self.rows, self.history, kind, self.zone)
            return self.capacity[kind][0]
        if kind not in self.calendar:
            self.calendar[kind] = calendar_periods(self.rows, kind, self.zone)
        return self.calendar[kind]

    def cards(self, small: bool) -> list[Panel]:
        if small in self.cards_cache:
            return self.cards_cache[small]
        now = datetime.now(timezone.utc)
        codex = self.latest.get("codex", (None, {}))[1]
        cards = []
        for name, field, minutes in (("LAST 5H · CODEX", "primary", 300),
                                     ("WEEKLY · CODEX", "secondary", 10080)):
            limit = codex.get(field)
            if (limit and limit.get("resets_at") and limit.get("window_minutes")
                    and int(limit["resets_at"]) > now.timestamp()):
                end = datetime.fromtimestamp(int(limit["resets_at"]), timezone.utc)
                start = end - timedelta(minutes=int(limit["window_minutes"]))
                note = f"Window {start.astimezone(self.zone):%d %b %H:%M} → {end.astimezone(self.zone):%d %b %H:%M}"
                current = [x for x in self.rows if start <= x.at < end]
            else:
                start = now - timedelta(minutes=minutes)
                current = [x for x in self.rows if start <= x.at <= now]
                note = "Approximate rolling window; no Codex reset data"
                limit = None
            cards.append(window_card(name, current, limit, self.zone, note, small))
        self.cards_cache[small] = cards
        return cards


def build(data: Dashboard, kind: str, offset: int,
          page_size: int, width: int = 80) -> tuple[Group, int]:
    periods = data.periods(kind)
    if kind in ("limit5", "limit7"):
        table, max_offset = capacity_table(periods, data.capacity[kind][1], kind,
                                           offset, page_size)
        title = "5-HOUR" if kind == "limit5" else "WEEKLY"
        table_title = f"{title} ALLOWANCE CAPACITY TREND · API-USD PROXY"
        subtitle = "Proxy uses priced local usage / allowance % change; ≥20 pp required"
    else:
        table, max_offset = period_table(periods, kind, offset, page_size)
        table_title = f"CALENDAR {kind.upper()}S"
        subtitle = "Weeks start Monday · local timezone"
    nav = Text.from_markup("[bold]d/w/m[/] calendar  ·  [bold]5/7[/] limit trend  ·  "
                           "[bold]j/k[/] scroll  ·  [bold]r[/] reload  ·  [bold]q[/] quit")
    footer_note = ("Trend can shift with model mix or missing local usage; not an exact limit" 
                   if kind in ("limit5", "limit7") else
                   "API price estimate, not ChatGPT charges · * contains unpriced models")
    footer = Text(f"{data.files} local rollouts · {len(data.rows)} usage records · {data.zone.key} · "
                  + footer_note,
                  style="dim")
    return Group(
        Panel(Text("CODEX USAGE", style="bold bright_white", justify="center"),
              border_style="bright_magenta"),
        Columns(data.cards(width < 112), equal=True, expand=True),
        Panel(table, title=f"{table_title}  ·  {offset + 1}–{min(offset + page_size, max_offset + page_size)}",
              subtitle=subtitle, border_style="magenta"),
        Panel(Group(nav, footer), border_style="dim"),
    ), max_offset


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--codex-home", type=Path,
                        default=Path(os.environ.get("CODEX_HOME", Path.home() / ".codex")))
    parser.add_argument("--timezone", help="IANA timezone; defaults to system local timezone")
    parser.add_argument("--refresh", type=float, default=30, metavar="SECONDS")
    args = parser.parse_args()
    if args.refresh <= 0:
        parser.error("--refresh must be positive")
    try:
        zone = ZoneInfo(args.timezone) if args.timezone else ZoneInfo(os.environ.get("TZ") or
                       (Path("/etc/localtime").resolve().as_posix().split("/zoneinfo/")[-1]))
    except Exception:
        zone = ZoneInfo("UTC")
    if not args.codex_home.is_dir():
        parser.error(f"Codex home does not exist: {args.codex_home}")
    console = Console()
    store = RolloutStore(args.codex_home)
    snapshot = store.load()
    data = Dashboard(snapshot, zone)
    kind, offset = "day", 0
    page_size = max(5, min(14, console.size.height - 22))
    if not sys.stdin.isatty() or not sys.stdout.isatty():
        view, _ = build(data, kind, offset, page_size, console.size.width)
        console.print(view)
        return 0
    original = termios.tcgetattr(sys.stdin.fileno())
    resize_read, resize_write = os.pipe2(os.O_NONBLOCK | os.O_CLOEXEC)
    previous_wakeup = signal.set_wakeup_fd(resize_write)
    previous_handler = signal.signal(signal.SIGWINCH, lambda *_: None)
    try:
        tty.setcbreak(sys.stdin.fileno())
        with Live(console=console, screen=True, auto_refresh=False) as live:
            next_refresh = time.monotonic() + args.refresh
            resize_due = 0.0
            dirty = True
            max_offset = 0
            while True:
                now = time.monotonic()
                if dirty and now >= resize_due:
                    size = console.size
                    page_size = max(3, min(14, size.height - 21))
                    offset = min(offset, max(0, len(data.periods(kind)) - page_size))
                    view, max_offset = build(data, kind, offset, page_size, size.width)
                    live.update(view, refresh=True)
                    dirty = False
                wake_at = min(next_refresh, resize_due) if dirty else next_refresh
                ready, _, _ = select.select(
                    [sys.stdin, resize_read], [], [],
                    max(0, wake_at - time.monotonic()))
                if resize_read in ready:
                    try:
                        os.read(resize_read, 4096)
                    except BlockingIOError:
                        pass
                    resize_due = time.monotonic() + 0.05
                    dirty = True
                if sys.stdin in ready:
                    key = sys.stdin.read(1).lower()
                    if key == "q":
                        break
                    if key in "dwm57":
                        new_kind = {"d": "day", "w": "week", "m": "month",
                                    "5": "limit5", "7": "limit7"}[key]
                        if new_kind != kind:
                            kind, offset = new_kind, 0
                            dirty = True
                    elif key == "j" and offset < max_offset:
                        offset += 1
                        dirty = True
                    elif key == "k" and offset:
                        offset -= 1
                        dirty = True
                    elif key == "r":
                        new_snapshot = store.load()
                        if new_snapshot is not snapshot:
                            snapshot = new_snapshot
                            data = Dashboard(snapshot, zone)
                        else:
                            data.cards_cache.clear()
                        dirty = True
                if time.monotonic() >= next_refresh:
                    new_snapshot = store.load()
                    if new_snapshot is not snapshot:
                        snapshot = new_snapshot
                        data = Dashboard(snapshot, zone)
                    else:
                        data.cards_cache.clear()
                    next_refresh = time.monotonic() + args.refresh
                    dirty = True
    finally:
        signal.signal(signal.SIGWINCH, previous_handler)
        signal.set_wakeup_fd(previous_wakeup)
        os.close(resize_read)
        os.close(resize_write)
        termios.tcsetattr(sys.stdin.fileno(), termios.TCSADRAIN, original)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
