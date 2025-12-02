#!/bin/bash

# GNOME Desktop Background Reset/Restore Script
# Usage: /path/to/script --reset   (to set default background)
#        /path/to/script --restore (to restore original background)

# Configuration
SETTINGS_KEY="org.gnome.desktop.background"
PICTURE_URI_KEY="picture-uri"
PICTURE_URI_DARK_KEY="picture-uri-dark"
BACKUP_FILE="$HOME/.gnome_background_backup"
FALLBACK_IMAGE="/usr/share/backgrounds/gnome/adwaita-l.jxl"

# Function to check if running in GNOME
check_gnome() {
    if ! command -v gsettings &> /dev/null; then
        echo "Error: gsettings command not found. Are you running GNOME?"
        exit 1
    fi
    
    # Check if the desktop is GNOME
    if [ "$XDG_CURRENT_DESKTOP" != "GNOME" ] && [ "$XDG_CURRENT_DESKTOP" != "ubuntu:GNOME" ]; then
        echo "Warning: You might not be running GNOME Desktop Environment."
        echo "Current desktop: $XDG_CURRENT_DESKTOP"
        read -p "Continue anyway? (y/n): " response
        if [[ "$response" != "y" && "$response" != "Y" ]]; then
            exit 1
        fi
    fi
}

# Function to backup current background settings
backup_current_settings() {
    current_bg=$(gsettings get $SETTINGS_KEY $PICTURE_URI_KEY)
    current_dark_bg=$(gsettings get $SETTINGS_KEY $PICTURE_URI_DARK_KEY 2>/dev/null || echo "")
    
    # Create backup file
    echo "PICTURE_URI=$current_bg" > "$BACKUP_FILE"
    
    # Only backup dark mode setting if it exists
    if [ -n "$current_dark_bg" ] && [ "$current_dark_bg" != "" ]; then
        echo "PICTURE_URI_DARK=$current_dark_bg" >> "$BACKUP_FILE"
    fi
    
    echo "Current background settings backed up to $BACKUP_FILE"
}

# Function to reset background to fallback
reset_background() {
    # Backup current settings if backup doesn't exist
    if [ ! -f "$BACKUP_FILE" ]; then
        backup_current_settings
    fi
    
    # Set fallback background
    gsettings set $SETTINGS_KEY $PICTURE_URI_KEY "'file://$FALLBACK_IMAGE'"
    
    # Set dark mode background if supported
    if gsettings get $SETTINGS_KEY $PICTURE_URI_DARK_KEY &>/dev/null; then
        gsettings set $SETTINGS_KEY $PICTURE_URI_DARK_KEY "'file://$FALLBACK_IMAGE'"
    fi
    
    echo "Background reset to fallback image"
}

# Function to restore original background
restore_background() {
    # Check if backup file exists
    if [ ! -f "$BACKUP_FILE" ]; then
        echo "Error: Backup file not found at $BACKUP_FILE"
        echo "Cannot restore previous background"
        exit 1
    fi
    
    # Source the backup file to get variables
    source "$BACKUP_FILE"
    
    # Restore settings
    gsettings set $SETTINGS_KEY $PICTURE_URI_KEY "$PICTURE_URI"
    
    # Restore dark mode setting if it was backed up
    if [ -n "$PICTURE_URI_DARK" ]; then
        gsettings set $SETTINGS_KEY $PICTURE_URI_DARK_KEY "$PICTURE_URI_DARK"
    fi
    
    echo "Original background restored"
}

# Main execution
check_gnome

case "$1" in
    --reset)
        reset_background
        ;;
    --restore)
        restore_background
        ;;
    *)
        echo "Usage: $0 --reset | --restore"
        echo ""
        echo "Options:"
        echo "  --reset    Backs up current background and sets it to fallback image"
        echo "  --restore  Restores previously backed up background"
        exit 1
        ;;
esac

exit 0
