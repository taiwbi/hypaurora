# --- 2B Picture and Praise ---

function fish_greeting
    # Check if tput exists, stdout is a terminal, TERM is set and not 'dumb'
    if command -v tput > /dev/null; and set -q TERM; and test "$TERM" != "dumb"
        set -l term_width (tput cols) # -l for local scope

        # Check terminal type
        if test "$TERM" = "xterm-ghostty" -o "$TERM" = "xterm-kitty"
            # Display image with kitten icat if conditions met
            if command -v kitten > /dev/null 2>&1; and test $term_width -gt 40
                set -l position (math $term_width - 26)
                # Fixed: Removed curly braces around the position variable
                kitten icat -n --place "25x18@$position"x0 "$HOME/Documents/hypaurora/assets/2B.png"
            end
        end

        # Display praise if terminal is wide enough
        if test $term_width -gt 80
            if test -x "$HOME/.config/fish/functions/praise.fish" # Check execute permission
                $HOME/.config/fish/functions/praise.fish
            else
                echo "Warning: Could not find executable praise.fish, check path/permissions."
            end
        end
    end
end
