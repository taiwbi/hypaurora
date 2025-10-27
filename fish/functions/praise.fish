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
set -l line (sed -n "$random_line"p "$FILE")

if test -z "$line"
    echo "Error: Selected line is empty" >&2
    exit 1
end

# ANSI color codes
set -l border (set_color red)
set -l reset (set_color normal)

# Get terminal width
set -l term_width 80
if command -v tput > /dev/null
    set term_width (tput cols)
end

# Calculate usable width
set -l usable_width (math $term_width - 23)
if test $usable_width -lt 30
    set usable_width 30
end

# Word-wrap the text
set -l words (string split " " -- "$line")
set -l current_line ""
set -l final_lines

for word in $words
    if test -z "$current_line"
        set current_line "$word"
    else if test (string length "$current_line $word") -le $usable_width
        set current_line "$current_line $word"
    else
        set final_lines $final_lines "$current_line"
        set current_line "$word"
    end
end

if test -n "$current_line"
    set final_lines $final_lines "$current_line"
end

# Find the longest line
set -l max_len 0
for fl in $final_lines
    set -l len (string length "$fl")
    if test $len -gt $max_len
        set max_len $len
    end
end

# Draw the box
set -l box_width (math $max_len + 2)
set -l dashes (string repeat -n $box_width ─)

# Top border
printf '%s╭%s╮%s\n' "$border" "$dashes" "$reset"

# Content lines
for fl in $final_lines
    set -l pad (math $max_len - (string length "$fl"))
    set -l pad_spaces (string repeat -n $pad " ")
    printf '%s│%s %s%s%s │%s\n' "$border" "$reset" "$fl" "$pad_spaces" "$border" "$reset"
end

# Bottom border
printf '%s╰%s╯%s\n' "$border" "$dashes" "$reset"

exit 0
