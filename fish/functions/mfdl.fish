function mfdl
    if test (count $argv) -eq 0
        echo "Usage: mfdl <mediafire_url>"
        return 1
    end

    set url $argv[1]

    set direct_url (
        curl -s $url| 
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
