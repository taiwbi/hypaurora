#!/bin/bash

BOOKMARKS_FILE="$HOME/.local/bashmarks"

# Ensure the bookmarks directory exists
mkdir -p "$(dirname "$BOOKMARKS_FILE")"
touch "$BOOKMARKS_FILE"

# Function to add a bookmark
sm() {
  if [ "$1" = "" ]; then
    echo "Usage: sm bookmark_name"
    return 1
  fi

  bookmark_name="$1"
  bookmark_path="$PWD"

    # Check if the bookmark already exists
    if grep -q "^$bookmark_name:" "$BOOKMARKS_FILE"; then
      echo "Bookmark '$bookmark_name' already exists."
      return 1
    fi

    echo "$bookmark_name:$bookmark_path" >> "$BOOKMARKS_FILE"
    echo "Added bookmark '$bookmark_name' -> '$bookmark_path'"
  }

# Function to list bookmarks
lm() {
  if [ ! -f "$BOOKMARKS_FILE" ]; then
    echo "No bookmarks found."
    return 0
  fi

  echo "Bookmarks:"
  printf "%-20s %s\n" "Bookmark Name" "Path"
  printf "%-20s %s\n" "--------------" "----"
  while IFS=: read -r name path; do
    printf "%-20s %s\n" "$name" "$path"
  done < "$BOOKMARKS_FILE"
}

# Function to go to a bookmarked directory
gm() {
  if [ "$1" = "" ]; then
    echo "Usage: gm bookmark_name"
    return 1
  fi

  bookmark_name="$1"
  bookmark_path=$(grep "^$bookmark_name:" "$BOOKMARKS_FILE" | cut -d: -f2)

  if [ "$bookmark_path" = "" ]; then
    echo "Bookmark '$bookmark_name' not found."
    return 1
  fi

  cd "$bookmark_path" || return 1
  echo "Changed directory to '$bookmark_path'"
}

# Function to delete a bookmark
dm() {
  if [ "$1" = "" ]; then
    echo "Usage: dm bookmark_name"
    return 1
  fi

  bookmark_name="$1"

  if ! grep -q "^$bookmark_name:" "$BOOKMARKS_FILE"; then
    echo "Bookmark '$bookmark_name' not found."
    return 1
  fi

  grep -v "^$bookmark_name:" "$BOOKMARKS_FILE" > "$BOOKMARKS_FILE.tmp"
  mv "$BOOKMARKS_FILE.tmp" "$BOOKMARKS_FILE"
  echo "Deleted bookmark '$bookmark_name'"
}

# Command handling
case "$1" in
  sm)
    sm "$2"
    ;;
  lm)
    lm
    ;;
  gm)
    gm "$2"
    ;;
  dm)
    dm "$2"
    ;;
esac
