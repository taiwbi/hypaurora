function set_proxy --description "Set socks proxy based on GNOME settings"
    # Check if gsettings command exists
    if not command -v gsettings > /dev/null
        return 1
    end

    # Get the proxy mode, remove single quotes, suppress stderr for schema errors
    set -l PROXY_MODE (gsettings get org.gnome.system.proxy mode 2>/dev/null | string trim -c "'")
    
    # Check if gsettings command succeeded (schema exists)
    if test $status -ne 0
        return 1
    end

    if test "$PROXY_MODE" = "manual"
        # Get the SOCKS proxy host and port, suppress stderr
        set -l SOCKS_HOST (gsettings get org.gnome.system.proxy.socks host 2>/dev/null | string trim -c "'")
        set -l SOCKS_PORT (gsettings get org.gnome.system.proxy.socks port 2>/dev/null)

        # Check if gsettings commands succeeded and values are reasonable
        if test $status -eq 0 -a -n "$SOCKS_HOST" -a "$SOCKS_PORT" -gt 0
            # Set the proxy environment variables (global and exported)
            set -gx all_proxy "socks5://$SOCKS_HOST:$SOCKS_PORT"
            set -gx ALL_PROXY "socks5://$SOCKS_HOST:$SOCKS_PORT"
        else
             # Ensure proxy vars are unset if config is bad
             set -e all_proxy
             set -e ALL_PROXY
        end
    else
        # Unset proxy variables if not in manual mode
        set -e all_proxy
        set -e ALL_PROXY
    end
end
