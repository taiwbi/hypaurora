function change_proxy
    if test (count $argv) -lt 1
        echo "Usage: set_proxy_host HOST PORT"
        return 1
    end

    set new_host $argv[1]
    if test (count $argv) -ge 2
        set new_port $argv[2]
    end

    if test "$new_host" = gateway
        echo "Calculating default gateway"
        set new_host (ip route | grep '^default' | awk '{print $3}')
    end

    echo "Setting $new_host as proxy's host"

    gsettings set org.gnome.system.proxy.http host "$new_host"
    gsettings set org.gnome.system.proxy.https host "$new_host"
    gsettings set org.gnome.system.proxy.ftp host "$new_host"
    gsettings set org.gnome.system.proxy.socks host "$new_host"

    if set -q new_port
        echo "Setting $new_port as proxy's port"

        gsettings set org.gnome.system.proxy.http port "$new_port"
        gsettings set org.gnome.system.proxy.http port "$new_port"
        gsettings set org.gnome.system.proxy.ftp port "$new_port"
        gsettings set org.gnome.system.proxy.socks port "$new_port"
    end
end
