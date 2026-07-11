function ipinfo --description "Get IP info from ipinfo.io"
    # Check if an argument (IP address) is provided
    if test -z "$argv[1]"
        echo "Usage: ipinfo <IP_ADDRESS>" >&2
        return 1
    end

    curl --silent "https://api.ipinfo.io/lite/$argv[1]?token=$(cat $HOME/.keys/IPINFO)"
end
