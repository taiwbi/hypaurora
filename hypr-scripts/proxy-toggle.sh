#!/bin/bash

STATUS=$(gsettings get org.gnome.system.proxy mode)

if [[ "$STATUS" == "'manual'" ]]; then
	gsettings set org.gnome.system.proxy mode "'none'"
	notify-send -a "Proxy Switch" -i "network-vpn-disabled-symbolic" "Proxy" "Proxy Turned Off"
else
	gsettings set org.gnome.system.proxy mode "'manual'"
	notify-send -a "Proxy Switch" -i "network-vpn-symbolic" "Proxy" "Proxy Turned on"
fi
