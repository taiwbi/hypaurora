#!/usr/bin/env bash

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
dir=$(basename "$cwd")
branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
model=$(echo "$input" | jq -r '.model.display_name // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')
five_used=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_used=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# Left: 5h:XX% 7d:XX%
left=""
if [ -n "$five_used" ]; then
  five_left=$(printf '%.0f' "$(echo "100 - $five_used" | bc)")
  left="5h:${five_left}%"
fi
if [ -n "$week_used" ]; then
  week_left=$(printf '%.0f' "$(echo "100 - $week_used" | bc)")
  [ -n "$left" ] && left="${left} "
  left="${left}7d:${week_left}%"
fi

# Right: dir_name | git_branch | model [effort]
right=""
[ -n "$dir" ]    && right="${dir}"
[ -n "$branch" ] && right="${right} | ${branch}"
if [ -n "$model" ]; then
  [ -n "$right" ] && right="${right} | "
  right="${right}${model}"
  [ -n "$effort" ] && right="${right} [${effort}]"
fi

# Get terminal width: try /dev/tty first (works even without TTY in env), then fallback
cols=$(stty size < /dev/tty 2>/dev/null | awk '{print $2}')
[ -z "$cols" ] && cols="${COLUMNS:-80}"

if [ -n "$left" ] && [ -n "$right" ]; then
  padding=$((cols - ${#left} - ${#right} - 4)) # For some reason I don't know it calculates 4 columns more
  [ "$padding" -lt 1 ] && padding=5
  printf "%s%*s%s" "$right" "$padding" "" "$left" # For some reasons I don't know, it prints them in reverse
elif [ -n "$right" ]; then
  printf "%s" "$right"
elif [ -n "$left" ]; then
  printf "%*%s" "$padding" "$left"
fi
