#!/usr/bin/fish

switch (uname -a)
case "*Android*" # Running on termux
  set -x ALL_PROXY socks5://127.0.0.1:1081
  set -x all_proxy socks5://127.0.0.1:1081

  if test -n "$no_proxy"
    set -x NO_PROXY $no_proxy
    set -x no_proxy $no_proxy
  end
case "*"
  set proxy_mode (gsettings get org.gnome.system.proxy mode | tr -d "'")
  if test "$proxy_mode" = "none"
    # Do Nothing
    true
  else
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
end
