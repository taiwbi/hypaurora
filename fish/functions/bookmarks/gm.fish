function gm --description "Go to a fishmarked directory"
    if test -z "$argv[1]"
        echo "Usage: gm <bookmark_name>" >&2
        return 1
    end

    set -l bookmark_name $argv[1]
    # Use grep and pipe to cut, trim whitespace
    set -l bookmark_path (grep -E "^$bookmark_name:" "$FISHMARKS_FILE" | string split -m 1 ':' -f 2 | string trim)

    if test -z "$bookmark_path"
        echo "Error: Fishmark '$bookmark_name' not found." >&2
        return 1
    end

    if not test -d "$bookmark_path"
         echo "Error: Marked directory '$bookmark_path' no longer exists." >&2
         # Optionally offer to delete the stale mark here
         return 1
    end

    cd "$bookmark_path"; or return 1 # Use ; or to handle cd errors
    echo "Changed directory to '$bookmark_path'"
end
