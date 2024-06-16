#!/usr/bin/fish

function set_proxy_variables
  set -l protocol $argv[1]
  set -l host (gsettings get org.gnome.system.proxy.$protocol host | tr -d "'")
  set -l port (gsettings get org.gnome.system.proxy.$protocol port)

  if test -n "$host" -a "$host" != "''" -a -n "$port"
    set -x (string upper $protocol)_PROXY http://$host:$port
    set -x (string lower $protocol)_proxy http://$host:$port
  end
end

set proxy_mode (gsettings get org.gnome.system.proxy mode | tr -d "'")

if test "$proxy_mode" = "none"
  # Do Nothing
  true
else
  # Set proxies for http, https, and all protocols
  set_proxy_variables "http"
  set_proxy_variables "https"

  # Fetch and set the proxy for all protocols
  set -l all_proxy_host (gsettings get org.gnome.system.proxy.socks host | tr -d "'")
  set -l all_proxy_port (gsettings get org.gnome.system.proxy.socks port)

  set -x ALL_PROXY socks5://$all_proxy_host:$all_proxy_port
  set -x all_proxy socks5://$all_proxy_host:$all_proxy_port

  # Fetch and set the no_proxy settings
  set -l no_proxy (gsettings get org.gnome.system.proxy ignore-hosts | tr -d "[]'")
  if test -n "$no_proxy"
    set -x NO_PROXY $no_proxy
    set -x no_proxy $no_proxy
  end
end
