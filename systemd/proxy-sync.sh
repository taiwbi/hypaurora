#!/bin/bash
# File: /usr/local/bin/proxy-sync.sh

# This script updates dnf and proxychains configuration files
# based on GNOME proxy settings for a specific user

# User whose settings we're monitoring
USER_ID=1000
USER_NAME=$(id -un "$USER_ID")
USER_HOME=$(eval echo ~"$USER_NAME")
DBUS_PATH="/run/user/$USER_ID/bus"

# Configuration files
DNF_CONF="/etc/dnf/dnf.conf"
PROXYCHAINS_CONF="/etc/proxychains.conf"
CONTINUE_CONF="$USER_HOME/.continue/config.yaml"
VSCODE_SETTINGS="$USER_HOME/.config/Cursor/User/settings.json"

# Function to strip ANSI escape sequences
strip_ansi() {
    # Remove all ANSI escape sequences
    sed 's/\x1b\[[0-9;?]*[a-zA-Z]//g' | sed 's/\x1b\[?[0-9]*[hl]//g'
}

# Function to run commands as the specific user
run_as_user() {
    local cmd="$1"
    
    # Set TERM to dumb to avoid terminal control sequences
    if [ "$(id -u)" -eq 0 ]; then
        # We're root, so use su without -l (login) to avoid PAM issues
        TERM=dumb su "$USER_NAME" -c "$cmd" 2>/dev/null
    else
        # Not root, probably running with sudo
        TERM=dumb sudo -u "$USER_NAME" bash -c "$cmd" 2>/dev/null
    fi
}

# Function to get GNOME settings
get_gsettings_value() {
    local schema="$1"
    local key="$2"
    
    # Set up environment to access user's dbus session
    local cmd="DBUS_SESSION_BUS_ADDRESS=unix:path=$DBUS_PATH gsettings get $schema $key"
    # Run command and strip ANSI sequences
    run_as_user "$cmd" | strip_ansi
}

# Function to update proxy settings
update_proxy_settings() {
    # Skip if dbus socket doesn't exist yet
    if [ ! -S "$DBUS_PATH" ]; then
        echo "D-Bus socket not available, skipping update"
        return
    fi

    # Get current proxy settings from GNOME for the specified user
    PROXY_HOST=$(get_gsettings_value org.gnome.system.proxy.socks host | tr -d "'")
    PROXY_PORT=$(get_gsettings_value org.gnome.system.proxy.socks port)

    # Additional cleanup - remove any remaining control characters
    PROXY_HOST=$(echo "$PROXY_HOST" | tr -cd '[:alnum:].-')
    PROXY_PORT=$(echo "$PROXY_PORT" | tr -cd '[:digit:]')

    # Skip if proxy settings are empty
    if [ -z "$PROXY_HOST" ] || [ "$PROXY_HOST" = "''" ]; then
        echo "Proxy host is not set, skipping update"
        return
    fi
    
    # Validate port number
    if ! [[ "$PROXY_PORT" =~ ^[0-9]+$ ]] || [ "$PROXY_PORT" -lt 1 ] || [ "$PROXY_PORT" -gt 65535 ]; then
        echo "Invalid proxy port: $PROXY_PORT"
        return
    fi
    
    echo "--- --- ---"
    echo "Updating proxy settings with host: $PROXY_HOST and port: $PROXY_PORT"

    # Update DNF configuration
    if [ -f "$DNF_CONF" ]; then
        # Check if proxy line already exists
        if grep -q "^proxy=" "$DNF_CONF"; then
            # Update existing proxy line
            sed -i "s|^proxy=.*|proxy=http://$PROXY_HOST:$PROXY_PORT|" "$DNF_CONF"
        else
            # Add proxy line to [main] section
            if grep -q "\[main\]" "$DNF_CONF"; then
                sed -i "/\[main\]/a proxy=http://$PROXY_HOST:$PROXY_PORT" "$DNF_CONF"
            else
                echo -e "\n[main]\nproxy=http://$PROXY_HOST:$PROXY_PORT" >> "$DNF_CONF"
            fi
        fi
        echo "Updated DNF configuration"
    else
        echo "DNF configuration file not found"
    fi

    # Update ProxyChains configuration
    if [ -f "$PROXYCHAINS_CONF" ]; then
        # Find the ProxyList section and update/add the socks5 line
        if grep -q "\[ProxyList\]" "$PROXYCHAINS_CONF"; then
            # Remove any existing socks5 line
            sed -i '/^socks5[[:space:]]/d' "$PROXYCHAINS_CONF"
            # Add new socks5 line
            sed -i "/\[ProxyList\]/a socks5 \t$PROXY_HOST $PROXY_PORT" "$PROXYCHAINS_CONF"
        else
            # Add ProxyList section if it doesn't exist
            echo -e "\n[ProxyList]\nsocks5 \t$PROXY_HOST $PROXY_PORT" >> "$PROXYCHAINS_CONF"
        fi
        echo "Updated ProxyChains configuration"
    else
        echo "ProxyChains configuration file not found"
    fi

    # Update SSH Config
    if [ -f "$USER_HOME/.ssh/config" ]; then
        # Command to update SSH config
        local cmd="sed -i 's/PROXY:.*:%h:%p,proxyport=[0-9]\\+/PROXY:$PROXY_HOST:%h:%p,proxyport=$PROXY_PORT/' '$USER_HOME/.ssh/config'"
        run_as_user "$cmd"
        echo "Updated SSH configuration"
    else
        echo "SSH configuration file not found"
    fi

    # Update Continue config.yaml
    if [ -f "$CONTINUE_CONF" ]; then
        # Command to update Continue config
        local cmd="sed -i 's|proxy: \"http://.*\"|proxy: \"http://$PROXY_HOST:$PROXY_PORT\"|' '$CONTINUE_CONF'"
        run_as_user "$cmd"
        echo "Updated Continue configuration"
    else
        echo "Continue configuration file not found"
    fi

    # Update VS Code settings.json
    if [ -f "$VSCODE_SETTINGS" ]; then
        # Command to update VS Code settings
        local cmd="sed -i 's|\"http.proxy\": \"http://.*\"|\"http.proxy\": \"http://$PROXY_HOST:$PROXY_PORT\"|' '$VSCODE_SETTINGS'"
        run_as_user "$cmd"
        echo "Updated VS Code settings"
    else
        echo "VS Code settings file not found"
    fi
}

# Start monitoring function
monitor_settings() {
    echo "Starting to monitor GNOME proxy settings for user $USER_NAME..."
    
    # Use a simple polling approach instead of dbus-monitor to avoid PAM issues
    # This is more reliable when running as a system service
    local prev_host=""
    local prev_port=""
    
    while true; do
        # Check if user session exists
        if [ -S "$DBUS_PATH" ]; then
            # Get current proxy settings
            local current_host=$(get_gsettings_value org.gnome.system.proxy.socks host 2>/dev/null | tr -d "'" || echo "")
            local current_port=$(get_gsettings_value org.gnome.system.proxy.socks port 2>/dev/null || echo "")
            
            # Additional cleanup for monitoring values
            current_host=$(echo "$current_host" | tr -cd '[:alnum:].-')
            current_port=$(echo "$current_port" | tr -cd '[:digit:]')
            
            # Check if settings changed
            if [ "$current_host" != "$prev_host" ] || [ "$current_port" != "$prev_port" ]; then
                echo "Proxy settings changed, updating configuration..."
                update_proxy_settings
                prev_host="$current_host"
                prev_port="$current_port"
            fi
            
            # Sleep for 10 seconds before checking again
            sleep 10
        else
            echo "Waiting for user session to become available..."
            sleep 5
        fi
    done
}

# Main execution
if [ "$1" = "monitor" ]; then
    echo "Initial setup at boot time..."
    
    # Try initial update at startup
    if [ -S "$DBUS_PATH" ]; then
        echo "D-Bus socket exists, listening for changes immediately"
        update_proxy_settings
    else
        echo "User not logged in yet, will update when session becomes available"
    fi
    
    # Start monitoring
    monitor_settings
else
    update_proxy_settings
fi
