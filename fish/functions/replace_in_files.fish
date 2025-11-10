# Replaces a string in all of the files in current directory with a new one
function replace_in_files
    # Check if correct number of arguments
    if test (count $argv) -ne 2
        echo "Usage: replace_in_files OLD_STRING NEW_STRING"
        return 1
    end

    set old_string $argv[1]
    set new_string $argv[2]

    # Build git ls-files command if .git directory exists
    if test -d .git
        # Use git ls-files to get tracked files (respects .gitignore)
        set files (git ls-files)
    else
        # Fallback to find if not in a git repo
        set files (find . -type f -not -path '*/.*' | sed 's|^\./||')
    end

    # Counter for changed files
    set changed_count 0

    # Iterate through each file
    for file in $files
        # Skip if file doesn't exist (in case of deleted files in git)
        test -f $file; or continue
        
        # Check if file contains the old string
        if grep -q -F -- $old_string $file 2>/dev/null
            # Perform the replacement
            sed -i "s/$old_string/$new_string/g" $file
            
            # Print the changed file path
            echo "Changed: $file"
            
            set changed_count (math $changed_count + 1)
        end
    end

    # Print summary
    echo ""
    echo "Total files changed: $changed_count"
end
