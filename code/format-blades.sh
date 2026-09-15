#!/usr/bin/env bash

set -euo pipefail

ROOT="${1:-.}"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)}"

for cmd in blade-safe-formatter blade-formatter html-class-wrapper; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "Error: $cmd is not available on PATH" >&2
        exit 1
    }
done

if [[ ! "$JOBS" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: JOBS must be a positive integer" >&2
    exit 1
fi

# Absolute paths also avoid filenames being interpreted as options.
ROOT="$(cd -- "$ROOT" && pwd -P)"

REPORT_DIR="$(mktemp -d)"
trap 'rm -rf -- "$REPORT_DIR"' EXIT

# Finish discovery before starting workers, so discovery errors abort safely.
find "$ROOT" \
    -type f \
    \( -name '*.blade.php' -o -name '*.blade.html' \) \
    -not -path '*/vendor/*' \
    -not -path '*/node_modules/*' \
    -print0 > "$REPORT_DIR/files"

if [[ ! -s "$REPORT_DIR/files" ]]; then
    echo "No Blade files found."
    exit 0
fi

echo "Formatting Blade files using $JOBS workers..."
echo ". unchanged  ✓ updated  ✗ failed"

pipeline_status=0

xargs -0 -n 1 -P "$JOBS" bash -c '
    set -euo pipefail

    report_dir="$1"
    file="$2"

    job="$(mktemp -d "$report_dir/job.XXXXXX")"
    printf "%s\0" "$file" > "$job/file"

    # Keep worker diagnostics out of the progress line.
    exec 2>"$job/error"

    formatted=""
    outcome="failed"

    finish() {
        local rc=$?
        trap - EXIT

        if [[ -n "$formatted" ]]; then
            rm -f -- "$formatted" || :
        fi

        if (( rc != 0 )); then
            outcome="failed"
        fi

        printf "%s\n" "$outcome" > "$job/status"

        case "$outcome" in
            unchanged) printf "." ;;
            completed) printf "✓" ;;
            failed)    printf "✗" ;;
        esac

        exit "$rc"
    }

    trap finish EXIT

    # Same-directory temporary file allows an atomic replacement.
    # Copy metadata before redirecting formatter output into it.
    formatted="$(mktemp "${file}.format.XXXXXX")"
    cp -p -- "$file" "$formatted"

    if ! blade-safe-formatter < "$file" > "$formatted"; then
        echo "blade-safe-formatter failed" >&2
        exit 1
    fi

    if grep -Eaqm1 \
        "^(Error:|SyntaxError:)|___attrs_[0-9]+___" \
        "$formatted"
    then
        echo "Formatter produced suspicious output:" >&2
        head -n 10 "$formatted" >&2
        exit 1
    fi

    if [[ ! -s "$formatted" && -s "$file" ]]; then
        echo "Formatter unexpectedly produced an empty file" >&2
        exit 1
    fi

    if cmp -s -- "$file" "$formatted"; then
        outcome="unchanged"
    else
        mv -f -- "$formatted" "$file"
        formatted=""
        outcome="completed"
    fi
' _ "$REPORT_DIR" < "$REPORT_DIR/files" || pipeline_status=$?

printf "\n"

completed=0
failed=0

shopt -s nullglob

for job in "$REPORT_DIR"/job.*; do
    IFS= read -r -d '' file < "$job/file"

    status="failed"
    if [[ -f "$job/status" ]]; then
        IFS= read -r status < "$job/status"
    fi

    case "$status" in
        completed)
            completed=$((completed + 1))
            printf "✓ %s\n" "$file"
            ;;
        failed)
            failed=$((failed + 1))
            printf "✗ %s\n" "$file"

            if [[ -s "$job/error" ]]; then
                sed "s/^/    /" "$job/error"
            else
                printf "    Worker failed without diagnostics.\n"
            fi
            ;;
    esac
done

printf "\nUpdated: %d  Failed: %d\n" "$completed" "$failed"

if (( pipeline_status != 0 || failed != 0 )); then
    echo "Formatting finished with errors." >&2
    exit 1
fi
