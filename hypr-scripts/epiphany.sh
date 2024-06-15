#!/bin/bash

set_proxy_variables() {
	local protocol=$1
	local host_key="org.gnome.system.proxy.$protocol host"
	local port_key="org.gnome.system.proxy.$protocol port"
	local host=$(gsettings get "$host_key" | tr -d "'")
	local port=$(gsettings get "$port_key")

	if [[ -n "$host" && "$host" != "''" && -n "$port" ]]; then
		export "${protocol^^}_PROXY=http://$host:$port"
		export "${protocol,,}_proxy=http://$host:$port"
	fi
}

proxy_mode=$(gsettings get org.gnome.system.proxy mode)
proxy_mode=$(echo "$proxy_mode" | tr -d "'")

if [[ "$proxy_mode" == "none" ]]; then
	epiphany
	exit
fi

# Set proxies for http, https, and all protocols
set_proxy_variables "http"
set_proxy_variables "https"

# Fetch and set the proxy for all protocols
all_proxy_host=$(gsettings get org.gnome.system.proxy.socks host | tr -d "'")
all_proxy_port=$(gsettings get org.gnome.system.proxy.socks port)

export ALL_PROXY="socks5://$all_proxy_host:$all_proxy_port"
export all_proxy="socks5://$all_proxy_host:$all_proxy_port"

# Fetch and set the no_proxy settings
no_proxy=$(gsettings get org.gnome.system.proxy ignore-hosts | tr -d "[]'")
if [[ -n "$no_proxy" ]]; then
	export NO_PROXY="$no_proxy"
	export no_proxy="$no_proxy"
fi

epiphany
