#!/bin/bash

# Configuration
API_KEY=$(cat ~/.keys/WALLHAVEN)
QUERY="${1:-id:479}"
DIR="$HOME/.config/background_dir"
HISTORY="$DIR/history.txt"

# Ensure directory exists
mkdir -p "$DIR"
touch "$HISTORY"

# Fetch results (Toplist, 3d, General/Anime, SFW)
RESPONSE=$(curl -s -G "https://wallhaven.cc/api/v1/search" \
    --data-urlencode "apikey=$API_KEY" \
    --data-urlencode "q=$QUERY" \
    --data-urlencode "sorting=toplist" \
    --data-urlencode "topRange=3d" \
    --data-urlencode "categories=110" \
    --data-urlencode "purity=100")

# Extract URLs and shuffle
URLS=$(echo "$RESPONSE" | jq -r '.data[].path' | shuf)

# Find first unused image
TARGET_URL=""
for url in $URLS; do
    if ! grep -Fxq "$url" "$HISTORY"; then
        TARGET_URL="$url"
        break
    fi
done

if [ -z "$TARGET_URL" ]; then
    echo "No new wallpapers found on page 1."
    exit 1
fi

# Download image
EXT="${TARGET_URL##*.}"
FILE_PATH="$DIR/wallpaper.$EXT"
curl -s -o "$FILE_PATH" "$TARGET_URL"

# Update History
echo "$TARGET_URL" >> "$HISTORY"

# Apply to GNOME
URI="file://$FILE_PATH"
gsettings set org.gnome.desktop.background picture-uri "$URI"
gsettings set org.gnome.desktop.background picture-uri-dark "$URI" # For dark mode

echo "Wallpaper changed to: $TARGET_URL"
