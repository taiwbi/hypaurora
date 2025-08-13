#!/bin/bash

function set_proxy {
    # Set socks proxy based on GNOME settings

    # Check if gsettings command exists
    if ! command -v gsettings > /dev/null 2>&1; then
        echo "Warning: gsettings command not found. Cannot set proxy." >&2
        return 1
    fi

    # Get the proxy mode, remove single quotes
    # Use tr to remove single quotes
    PROXY_MODE=$(gsettings get org.gnome.system.proxy mode | tr -d "'")

    if [ "$PROXY_MODE" = "manual" ]; then
        # Get the SOCKS proxy host and port
        SOCKS_HOST=$(gsettings get org.gnome.system.proxy.socks host | tr -d "'")
        SOCKS_PORT=$(gsettings get org.gnome.system.proxy.socks port)

        # Check if host is not empty and port is a number greater than 0
        # -n checks for non-empty string
        # > is used for numerical comparison within (( )) or [ ] with -gt
        if [ -n "$SOCKS_HOST" ] && [ "$SOCKS_PORT" -gt 0 ] 2>/dev/null; then # 2>/dev/null suppresses errors if SOCKS_PORT is not a number
            # Set the proxy environment variables (global and exported)
            export all_proxy="socks5://$SOCKS_HOST:$SOCKS_PORT"
            export ALL_PROXY="socks5://$SOCKS_HOST:$SOCKS_PORT"
            # echo "Proxy set to socks5://$SOCKS_HOST:$SOCKS_PORT" # Optional debug message
        else
            echo "Warning: Manual proxy mode detected, but SOCKS host/port not configured or invalid." >&2
            # Ensure proxy vars are unset if config is bad
            unset all_proxy
            unset ALL_PROXY
        fi
    else
        # Unset proxy variables if not in manual mode
        unset all_proxy
        unset ALL_PROXY
        # echo "Proxy disabled (mode: $PROXY_MODE)." # Optional debug message
    fi
}

set_proxy

export DEEPINFRA_KEY=$(cat "/home/mahdi/.keys/DEEPINFRA")
export GEMINI_KEY=$(cat "/home/mahdi/.keys/GEMINI_mahditaiw")
export OPENROUTER_KEY=$(cat "$HOME/.keys/OPENROUTER")
export PHP_CS_FIXER_IGNORE_ENV=true

ghostty --gtk-titlebar=false --class="org.nvim.neovide" -e nvim "$@"
# neovide --wayland_app_id org.nvim.neovide --frame none "$@"
