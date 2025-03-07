eval "$(fzf --bash)"
set completion-ignore-case on

# Setup proxy
set_proxy() {
  # Get the proxy mode
  PROXY_MODE=$(gsettings get org.gnome.system.proxy mode | tr -d "'")

  if [ "$PROXY_MODE" = "manual" ]; then
    # Get the SOCKS proxy host and port
    SOCKS_HOST=$(gsettings get org.gnome.system.proxy.socks host | tr -d "'")
    SOCKS_PORT=$(gsettings get org.gnome.system.proxy.socks port)

    # Set the proxy environment variables
    export all_proxy="socks5://$SOCKS_HOST:$SOCKS_PORT"
    export ALL_PROXY="socks5://$SOCKS_HOST:$SOCKS_PORT"
  else
    # Unset proxy variables if not in manual mode
    unset http_proxy
    unset https_proxy
  fi
}

# Call the function to set the proxy when the shell starts
set_proxy
