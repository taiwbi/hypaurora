function dm --description "Delete a fishmark"
    if test -z "$argv[1]"
        echo "Usage: dm <bookmark_name>" >&2
        return 1
    end

    set -l bookmark_name $argv[1]

    # Check if the bookmark exists before trying to delete
    if not grep -q -E "^$bookmark_name:" "$FISHMARKS_FILE"
        echo "Error: Fishmark '$bookmark_name' not found." >&2
        return 1
    end

    # Use grep -v to filter out the line and overwrite the file
    set -l tmp_file (mktemp)
    grep -v -E "^$bookmark_name:" "$FISHMARKS_FILE" >"$tmp_file"
    # Check if grep succeeded before moving
    if test $status -eq 0
        mv "$tmp_file" "$FISHMARKS_FILE"
        echo "Deleted fishmark '$bookmark_name'"
    else
        echo "Error: Failed to filter bookmark file." >&2
        rm -f "$tmp_file" # Clean up temp file on error
        return 1
        fi
    end
