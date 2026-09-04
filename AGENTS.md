# Repository Guidelines

## Project Structure & Module Organization

Hypaurora is a personal Linux dotfiles repository, not a compiled application. Desktop configuration is grouped by consumer: `hypr/`, `waybar/`, `kitty/`, `gtk-3.0/`, `gtk-4.0/`, `qt/`, `mpv/`, `fish/`, and `bash/`. Session integration lives in `systemd/user/`, `dbus-1/`, `xdg-desktop-portal/`, `uwsm/`, and `hyprpolkitagent/`. Reusable automation is in `scripts/` and `code/`; themes and other static resources are in `assets/` and application-specific theme directories. `README.md` documents the CachyOS/Hyprland setup.

## Build, Test, and Development Commands

There is no build system or automated test suite. Use these commands while developing:

```bash
./scripts/link.sh                 # interactively link configs; backs up targets
./scripts/link.sh --yes           # non-interactive linking from installation.sh
./scripts/installation.sh         # CachyOS-only package install and linking
bash -n scripts/*.sh code/*.sh    # shell syntax validation
python -m py_compile scripts/nautilus-portal-proxy.py code/zora.py
git diff --check                  # whitespace/error check
```

`installation.sh` changes packages and user services, while `link.sh` changes the home directory; review both before running. Validate desktop changes in a Hyprland session with `systemctl --user --failed` and relevant service status commands.

## Coding Style & Naming Conventions

Keep application and service paths aligned with their target names. Use Bash with `set -Eeuo pipefail` for new automation, quote expansions and paths, prefer `[[ ... ]]`, and use lowercase `snake_case` for local variables/functions. Python helpers should follow readable PEP 8 style, with constants in `UPPER_SNAKE_CASE`. Preserve existing config syntax and comments; use descriptive filenames such as `hyprland-per-window-layout.service` and avoid unrelated reformatting.

## Testing Guidelines

For configuration-only changes, test the affected application or service after linking. For scripts, run syntax checks and, when available, `shellcheck scripts/<file>.sh`; use dry-run or help modes where provided (for example, `scripts/cleanup-wm.sh --dry-run`). Do not run destructive cleanup or GSettings scripts merely as a test.

## Commit & Pull Request Guidelines

Recent history uses Conventional Commit-style subjects such as `feat(hypr): ...`, `fix(portals): ...`, `chore(kitty): ...`, and `style(waybar): ...`. Keep commits focused and explain user-visible behavior. PRs should describe affected configurations, target CachyOS/Hyprland assumptions, validation performed, backup or migration concerns, and include screenshots for visual/theme changes. Do not commit secrets, machine-specific credentials, generated caches, or personal absolute paths.
