#!/usr/bin/env bash

set -euo pipefail

ROOT="${1:-.}"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)}"

if ! command -v blade-formatter >/dev/null 2>&1; then
    echo "Error: blade-formatter is not available on PATH" >&2
    exit 1
fi

if ! command -v html-class-wrapper >/dev/null 2>&1; then
    echo "Error: html-class-wrapper is not available on PATH" >&2
    exit 1
fi

echo "Formatting Blade files using $JOBS parallel jobs..."

find "$ROOT" \
    -type f \
    \( -name '*.blade.php' -o -name '*.blade.html' \) \
    -not -path '*/vendor/*' \
    -not -path '*/node_modules/*' \
    -print0 |
    xargs -0 -r -n 1 -P "$JOBS" bash -c '
        file="$1"
        tmp="$(mktemp)"

        cleanup() {
            rm -f "$tmp"
        }
        trap cleanup EXIT

        if blade-formatter \
            --stdin \
            --sort-tailwindcss-classes \
            --indent-inner-html \
            < "$file" |
            html-class-wrapper > "$tmp"
        then
            mv "$tmp" "$file"
            trap - EXIT
            printf "✓ %s\n" "$file"
        else
            printf "✗ %s\n" "$file" >&2
            exit 1
        fi
    ' _

echo "Done."

echo
echo "Validating Blade templates..."

php artisan view:clear
php artisan view:cache

echo "✓ All Blade templates compiled successfully."
