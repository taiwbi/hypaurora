function ipinfo --description "Get IP info from ipinfo.io"
    # Check if an argument (IP address) is provided
    if test -z "$argv[1]"
        echo "Usage: ipinfo <IP_ADDRESS>" >&2
        return 1
    end
    curl --silent -H "Authorization: Bearer $(cat $HOME/.keys/IPINFO)" "https://api.ipinfo.io/lite/$argv[1]"
end
