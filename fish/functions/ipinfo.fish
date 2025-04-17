function ipinfo --description "Get IP info from ip-api.com"
    # Check if an argument (IP address) is provided
    if test -z "$argv[1]"
        echo "Usage: ipinfo <IP_ADDRESS>" >&2
        return 1
    end
    curl --silent --fail "http://ip-api.com/json/$argv[1]" | jq
end
