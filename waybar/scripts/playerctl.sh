#!/bin/bash

# Default priority order of players
players=("cmus" "Lollypop" "io.bassi.Amberol" "TelegramDesktop" "org.telegram.desktop" "brave.instance2")

while true; do
  # Initialize variables
  selected_player=""
  
  # First check if any player is playing
  all_players=$(playerctl -l 2>/dev/null)
  for player in "${all_players[@]}"; do
    status=$(playerctl -p "$player" status 2>/dev/null)
    if [[ "$status" == "Playing" ]]; then
      selected_player=$player
      break
    fi
  done

  # If no player is playing, fall back to priority order
  if [[ -z "$selected_player" ]]; then
    for player in "${players[@]}"; do
      status=$(playerctl -p "$player" status 2>/dev/null)
      if [[ -n "$status" ]]; then
        selected_player=$player
        break
      fi
    done
  fi

  # Get status for the selected player
  if [[ -n "$selected_player" ]]; then
    playerctl_status=$(playerctl -p "$selected_player" status 2>/dev/null)
    loop_stats=$(playerctl -p "$selected_player" loop 2>/dev/null)
  else
    playerctl_status=$(playerctl status 2>/dev/null)
    loop_stats=$(playerctl loop 2>/dev/null)
  fi

  if [[ $playerctl_status == "Playing" ]]; then
    if [[ -n "$selected_player" ]]; then
      title=$(playerctl -p "$selected_player" metadata title 2>/dev/null)
    else
      title=$(playerctl metadata title 2>/dev/null)
    fi
    icon=" "
  elif [[ $playerctl_status == "Paused" ]]; then
    if [[ -n "$selected_player" ]]; then
      title=$(playerctl -p "$selected_player" metadata title 2>/dev/null)
    else
      title=$(playerctl metadata title 2>/dev/null)
    fi
    icon=" "
  else
    echo 'No Music '
    sleep 3
    continue
  fi

  if [[ $loop_stats == "None" ]]; then
    end_icon=""
  elif [[ $loop_stats == "Track" ]]; then
    end_icon=""
  elif [[ $loop_stats == "Playlist" ]]; then
    end_icon=""
  fi
    
  # Truncate the title to fit within 16 characters
  max_length=32
  output="$icon$end_icon $title"
  if [[ ${#output} -gt $max_length ]]; then
    output="${output:0:$((max_length-3))}..."
  fi

  echo "$output"
  sleep 0.15
done
