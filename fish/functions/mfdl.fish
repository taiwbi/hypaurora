function mfdl
    if test (count $argv) -eq 0
        echo "Usage: mfdl <mediafire_url>"
        return 1
    end

    set url $argv[1]
    set ua 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36'

    set direct_url (
        curl -fsSL --compressed \
        --retry 3 \
        --retry-delay 2 \
        --connect-timeout 10 \
        --max-time 60 \
        -A $ua \
        -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
        -H 'Accept-Language: en-US,en;q=0.9' \
        -H 'Upgrade-Insecure-Requests: 1' \
        $url |
        grep --color=never -Eo 'https://download[0-9]*\.mediafire\.com/[^"]+' |
        head -1
    )

    if test -z "$direct_url"
        echo "Error: Could not extract download link from $url"
        return 1
    end

    echo "Downloading: $direct_url"
    aria "$direct_url"
end
