function sm --description "Save current directory as a fishmark"
    if test -z "$argv[1]"
        echo "Usage: sm <bookmark_name>" >&2
        return 1
    end

    set -l bookmark_name $argv[1]
    set -l bookmark_path (pwd)

    # Check if the bookmark already exists (case-sensitive)
    if grep -q -E "^$bookmark_name:" "$FISHMARKS_FILE"
        echo "Error: Fishmark '$bookmark_name' already exists." >&2
        return 1
    end

    # Append the new bookmark
    echo "$bookmark_name:$bookmark_path" >> "$FISHMARKS_FILE"
    echo "Added fishmark '$bookmark_name' -> '$bookmark_path'"
end
