#!/bin/bash

NO_PROXY="['localhost', '127.0.0.0/8', '::1', '192.168.0.0/16']"

while true; do

	# Get the current SSID
	SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d':' -f2)
	echo "$SSID"

	# Set the proxy configuration based on the SSID
	case "$SSID" in
	"Mati")
		HOST="192.168.43.1"
		PORT=1080
		;;
	"Tayebi")
		HOST="192.168.1.102"
		PORT=1080
		;;
	*)
		HOST="127.0.0.1"
		PORT=1080
		;;
	esac

	# Update the proxy
	gsettings set org.gnome.system.proxy.socks host "$HOST"
	gsettings set org.gnome.system.proxy.http host "$HOST"
	gsettings set org.gnome.system.proxy.https host "$HOST"
	gsettings set org.gnome.system.proxy ignore-hosts "$NO_PROXY"

	sleep 18

done
