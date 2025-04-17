function lm --description "List all fishmarks"
    if not test -f "$FISHMARKS_FILE"; or not test -s "$FISHMARKS_FILE" # check exists and not empty
        echo "No fishmarks found."
        return 0
    end

    echo "Fishmarks:"
    printf "%-25s %s\n" "Bookmark Name" "Path"
    printf "%-25s %s\n" "-------------------------" "----"
    # Use read loop with string split
    while read -l line
        # Handle potential empty lines gracefully
        if test -n "$line"
           set -l parts (string split -m 1 ':' -- "$line")
           if test (count $parts) -eq 2
              printf "%-25s %s\n" "$parts[1]" "$parts[2]"
           end
        end
    end < "$FISHMARKS_FILE"
end
