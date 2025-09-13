function set_proxy --description "Set proxy based on GNOME settings (supports SOCKS, HTTP, HTTPS, FTP)"
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
        # Function to set proxy if host and port are valid
        function _set_proxy_if_valid --argument-names proxy_type host port var_name
            if test -n "$host" -a "$port" -gt 0 2>/dev/null
                set -gx $var_name "$proxy_type://$host:$port"
                return 0
            end
            return 1
        end

        # Get HTTP proxy settings
        set -l HTTP_HOST (gsettings get org.gnome.system.proxy.http host 2>/dev/null | string trim -c "'")
        set -l HTTP_PORT (gsettings get org.gnome.system.proxy.http port 2>/dev/null)
        
        # Get HTTPS proxy settings (use HTTP as fallback if HTTPS not set)
        set -l HTTPS_HOST (gsettings get org.gnome.system.proxy.https host 2>/dev/null | string trim -c "'")
        set -l HTTPS_PORT (gsettings get org.gnome.system.proxy.https port 2>/dev/null)
        
        # Get FTP proxy settings
        set -l FTP_HOST (gsettings get org.gnome.system.proxy.ftp host 2>/dev/null | string trim -c "'")
        set -l FTP_PORT (gsettings get org.gnome.system.proxy.ftp port 2>/dev/null)
        
        # Get SOCKS proxy settings
        set -l SOCKS_HOST (gsettings get org.gnome.system.proxy.socks host 2>/dev/null | string trim -c "'")
        set -l SOCKS_PORT (gsettings get org.gnome.system.proxy.socks port 2>/dev/null)

        # Set proxy variables if valid
        set -l proxy_set 0
        
        # Set HTTP proxy
        if _set_proxy_if_valid "http" "$HTTP_HOST" "$HTTP_PORT" "http_proxy"
            set -gx HTTP_PROXY "$http_proxy"
            set proxy_set 1
        end
        
        # Set HTTPS proxy (fallback to HTTP proxy if HTTPS not configured)
        if _set_proxy_if_valid "http" "$HTTPS_HOST" "$HTTPS_PORT" "https_proxy"
            set -gx HTTPS_PROXY "$https_proxy"
            set proxy_set 1
        else if test -n "$http_proxy"
            set -gx https_proxy "$http_proxy"
            set -gx HTTPS_PROXY "$http_proxy"
            set proxy_set 1
        end
        
        # Set FTP proxy
        if _set_proxy_if_valid "http" "$FTP_HOST" "$FTP_PORT" "ftp_proxy"
            set -gx FTP_PROXY "$ftp_proxy"
            set proxy_set 1
        end
        
        # Set SOCKS proxy
        if _set_proxy_if_valid "socks5" "$SOCKS_HOST" "$SOCKS_PORT" "all_proxy"
            set -gx ALL_PROXY "$all_proxy"
            set proxy_set 1
        end
        
        # Get ignore hosts (no_proxy)
        set -l IGNORE_HOSTS (gsettings get org.gnome.system.proxy ignore-hosts 2>/dev/null)
        if test $status -eq 0 -a -n "$IGNORE_HOSTS"
            # Convert GNOME's array format to comma-separated list
            set -l no_proxy_list (echo "$IGNORE_HOSTS" | string replace -a "['" "" | string replace -a "']" "" | string replace -a "', '" ",")
            if test -n "$no_proxy_list"
                set -gx no_proxy "$no_proxy_list"
                set -gx NO_PROXY "$no_proxy_list"
            end
        end
        
        # Clean up helper function
        functions -e _set_proxy_if_valid
        
        # If no proxies were set successfully, ensure vars are unset
        if test $proxy_set -eq 0
            set -e http_proxy HTTP_PROXY https_proxy HTTPS_PROXY
            set -e ftp_proxy FTP_PROXY all_proxy ALL_PROXY
            set -e no_proxy NO_PROXY
        end
    else
        # Unset all proxy variables if not in manual mode
        set -e http_proxy HTTP_PROXY https_proxy HTTPS_PROXY
        set -e ftp_proxy FTP_PROXY all_proxy ALL_PROXY
        set -e no_proxy NO_PROXY
    end
end
