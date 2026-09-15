#!/usr/bin/env python3

import json
import shutil
import subprocess
import sys
from datetime import datetime

try:
    from rich.console import Console
    from rich.progress import ProgressBar
    from rich.table import Table
except ImportError:
    print("Missing dependency: rich")
    print("Install it with: python3 -m pip install rich")
    sys.exit(1)


console = Console()
CODEX = shutil.which("codex")


def die(message):
    console.print(f"[bold red]Error:[/] {message}")
    sys.exit(1)


def send(proc, message):
    proc.stdin.write(json.dumps(message) + "\n")
    proc.stdin.flush()


def wait_for_id(proc, request_id):
    while True:
        line = proc.stdout.readline()

        if not line:
            die("Codex app-server exited unexpectedly.")

        try:
            message = json.loads(line)
        except json.JSONDecodeError:
            continue

        if message.get("id") == request_id:
            if "error" in message:
                die(str(message["error"]))

            return message.get("result", {})


def format_reset(timestamp):
    if not timestamp:
        return "Unknown"

    try:
        dt = datetime.fromtimestamp(timestamp).astimezone()
        now = datetime.now().astimezone()

        days = (dt.date() - now.date()).days

        if days == 0:
            return f"Today {dt:%H:%M}"

        if days == 1:
            return f"Tomorrow {dt:%H:%M}"

        if days < 7:
            return dt.strftime("%A %H:%M")

        return dt.strftime("%a %d %b %H:%M")

    except (TypeError, ValueError, OSError):
        return str(timestamp)


def duration_name(minutes):
    if minutes == 300:
        return "5h"

    if minutes == 1440:
        return "Day"

    if minutes == 10080:
        return "Weekly"

    if not minutes:
        return "Limit"

    if minutes % 1440 == 0:
        return f"{minutes // 1440}d"

    if minutes % 60 == 0:
        return f"{minutes // 60}h"

    return f"{minutes}m"


def usage_color(used):
    if used >= 90:
        return "red"

    if used >= 70:
        return "yellow"

    return "green"


def usage_line(window):
    if not window:
        return

    used = window.get("usedPercent")
    reset = window.get("resetsAt")
    minutes = window.get("windowDurationMins")

    label = duration_name(minutes)

    if not isinstance(used, (int, float)):
        used = 0

    used = max(0, min(100, used))
    color = usage_color(used)

    table = Table.grid(expand=True)

    table.add_column(width=8)
    table.add_column(ratio=1)
    table.add_column(width=7, justify="right")
    table.add_column(width=24)

    table.add_row(
        f"[bold]{label}[/]",
        ProgressBar(
            total=100,
            completed=used,
            width=None,
        ),
        f"[bold {color}]{used:g}%[/]",
        f"[dim] reset[/] [cyan]{format_reset(reset)}[/]",
    )

    console.print(table)


def main():
    if not CODEX:
        die("'codex' was not found in PATH.")

    proc = subprocess.Popen(
        [CODEX, "app-server", "--stdio"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        bufsize=1,
    )

    try:
        # Initialize Codex app-server
        send(
            proc,
            {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "initialize",
                "params": {
                    "clientInfo": {
                        "name": "codex-usage",
                        "title": "Codex Usage",
                        "version": "3.0.0",
                    },
                    "capabilities": {},
                },
            },
        )

        wait_for_id(proc, 1)

        send(
            proc,
            {
                "jsonrpc": "2.0",
                "method": "initialized",
                "params": {},
            },
        )

        # Read usage/rate limits
        send(
            proc,
            {
                "jsonrpc": "2.0",
                "id": 2,
                "method": "account/rateLimits/read",
            },
        )

        result = wait_for_id(proc, 2)
        limits = result.get("rateLimits")

        if not limits:
            die(
                "No rate-limit information returned. "
                "Make sure you're logged in with `codex login`."
            )

        plan = limits.get("planType")
        reached = limits.get("rateLimitReachedType")

        if reached:
            status = f"[bold red]✗ {reached}[/]"
        else:
            status = "[bold green]✓ Available[/]"

        plan_text = str(plan).title() if plan else "Unknown"

        console.print()
        console.print(
            f"[bold bright_white]CODEX[/]  " f"[cyan]{plan_text}[/]  " f"{status}"
        )
        console.print()

        usage_line(limits.get("primary"))
        usage_line(limits.get("secondary"))

        credits = limits.get("credits")

        if credits:
            if credits.get("unlimited"):
                credit_text = "Unlimited"
            elif credits.get("balance") is not None:
                credit_text = str(credits["balance"])
            elif not credits.get("hasCredits", False):
                credit_text = "None"
            else:
                credit_text = "Unknown"

            console.print(f"\n[dim]Credits[/]  " f"[cyan]{credit_text}[/]")

        reset_credits = result.get("rateLimitResetCredits")

        if reset_credits:
            count = reset_credits.get("availableCount", 0)

            if count:
                console.print(f"[dim]Resets[/]   " f"[cyan]{count} available[/]")

        console.print(f"\n[dim]Updated " f"{datetime.now().astimezone():%H:%M}[/]")
        console.print()

    finally:
        try:
            proc.terminate()
            proc.wait(timeout=2)
        except Exception:
            proc.kill()


if __name__ == "__main__":
    main()
