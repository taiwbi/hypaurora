function set_proxy --description "Set socks proxy based on GNOME settings"
    # Check if gsettings command exists
    if not command -v gsettings > /dev/null
        echo "Warning: gsettings command not found. Cannot set proxy." >&2
        return 1
    end

    # Get the proxy mode, remove single quotes
    set -l PROXY_MODE (gsettings get org.gnome.system.proxy mode | string trim -c "'")

    if test "$PROXY_MODE" = "manual"
        # Get the SOCKS proxy host and port
        set -l SOCKS_HOST (gsettings get org.gnome.system.proxy.socks host | string trim -c "'")
        set -l SOCKS_PORT (gsettings get org.gnome.system.proxy.socks port)

        # Check if host and port are reasonably set
        if test -n "$SOCKS_HOST" -a "$SOCKS_PORT" -gt 0
            # Set the proxy environment variables (global and exported)
            set -gx all_proxy "socks5://$SOCKS_HOST:$SOCKS_PORT"
            set -gx ALL_PROXY "socks5://$SOCKS_HOST:$SOCKS_PORT"
            # echo "Proxy set to socks5://$SOCKS_HOST:$SOCKS_PORT" # Optional debug message
        else
             echo "Warning: Manual proxy mode detected, but SOCKS host/port not configured." >&2
             # Ensure proxy vars are unset if config is bad
             set -e all_proxy
             set -e ALL_PROXY
        end
    else
        # Unset proxy variables if not in manual mode
        set -e all_proxy
        set -e ALL_PROXY
        # echo "Proxy disabled (mode: $PROXY_MODE)." # Optional debug message
    end
end
