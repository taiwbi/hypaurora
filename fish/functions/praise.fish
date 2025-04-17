#!/usr/bin/env fish

set -l FILE $HOME/Documents/hypaurora/assets/2BPraise.txt

if not test -f "$FILE"
    echo "Error: Praise file not found at $FILE" >&2
    exit 1
end

set -l total_lines (wc -l < "$FILE" | string trim)

if test "$total_lines" -eq 0
    echo "Error: Praise file is empty or unreadable." >&2
    exit 1
end

set -l random_line (random 1 $total_lines)
# Fixed sed expression by removing curly braces
set -l line (sed -n "$random_line"p "$FILE")
set -l line_length (string length -- "$line")

if test $line_length -le 80
    echo "$line"
    exit 0
end

# --- Line needs wrapping ---

# Get the first 80 characters
set -l first_part (string sub -l 80 -- "$line")

# Find the last space in the first part
set -l last_space_match (string match -r '.*( [^ ]*)$' -- "$first_part")

if test -n "$last_space_match[1]"
    set -l last_space_group_len (string length -- "$last_space_match[2]") # Length of " word"
    set -l split_pos (math 80 - $last_space_group_len)

    echo (string sub -l $split_pos -- "$line")
    echo (string sub -s (math $split_pos + 2) -- "$line") # +2 to skip the space itself
else
    echo (string sub -l 80 -- "$line")
    echo (string sub -s 81 -- "$line")
end

exit 0
