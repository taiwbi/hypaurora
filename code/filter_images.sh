#!/bin/bash

# Usage: ./filter_images.sh [wide|port]
# Filters images based on their dimensions and creates symlinks in the current directory

# Default to landscape/wide
TYPE=${1}
TARGET_DIR="hor"
OP=">"

if [[ "$TYPE" == "port" ]]; then
    TARGET_DIR="port"
    OP="<"
elif [[ "$TYPE" == "wide" ]]; then
    TARGET_DIR="wide"
    OP=">"
else
    echo "Usage: $0 [wide|port]"
    exit 1
fi

mkdir -p "$TARGET_DIR"

# Filter images and create symlinks
exiftool -m -if "\$ImageWidth $OP \$ImageHeight" -p '$Directory/$FileName' -q -f . | while read -r img; do
    ln -s "$(realpath "$img")" "$TARGET_DIR/$(basename "$img")"
done

echo "Done! Symlinks created in ./$TARGET_DIR"
