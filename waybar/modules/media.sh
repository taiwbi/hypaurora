#!/bin/bash

function name() {
  playerctl_status=$(playerctl status 2>/dev/null)
  if [[ $playerctl_status == "Playing" ]]; then
    icon="󰎈"
    complete_track=$(playerctl metadata title)
    track=${complete_track:0:16}
    complete_artist=$(playerctl metadata artist)
  elif [[ $playerctl_status == "Paused" ]]; then
    icon="󰏤"
    complete_track=$(playerctl metadata title)
    track=${complete_track:0:16}
    complete_artist=$(playerctl metadata artist)
  else
    text=""
    tooltip=""
    echo -e "{\"text\": \"$text\", \"tooltip\": \"$tooltip\" }"
    exit;
  fi
  artist=${complete_artist:0:10}
  text=" $track - $artist"
  text="${text//\"/\\\"}"
  tooltip="$icon $complete_track - $complete_artist"
  tooltip="${tooltip//\"/\\\"}"
  tooltip=${tooltip:0:39}
  echo -e "{\"text\": \"$text\", \"tooltip\": \"$tooltip\" }"
}

function previous(){
  playerctl_status=$(playerctl status 2>/dev/null)
  if [[ $playerctl_status == "Playing" || $playerctl_status == "Paused" ]]; then
    echo -e "{\"text\": \"󰙣 \" }"
  else
    echo -e "{\"text\": \"\" }"
  fi
  sleep 0.4
}

function next(){
  playerctl_status=$(playerctl status 2>/dev/null)
  if [[ $playerctl_status == "Playing" || $playerctl_status == "Paused" ]]; then
    echo -e "{\"text\": \"󰙡 \" }"
  else
    echo -e "{\"text\": \"\" }"
  fi
  sleep 0.4
}

function toggle(){
  playerctl_status=$(playerctl status 2>/dev/null)
  if [[ $playerctl_status == "Playing" ]]; then
    echo -e "{\"text\": \"󰏥 \" }"
  elif [[ $playerctl_status == "Paused" ]]; then
    echo -e "{\"text\": \"󰐌 \" }"
  else
    echo -e "{\"text\": \"\" }"
  fi
  sleep 0.4
}

case "$1" in
  --name )
    name
    ;;
  --next )
    next
    ;;
  --previous )
    previous
    ;;
  --toggle )
    toggle
    ;;
  * )
    exit;
esac

