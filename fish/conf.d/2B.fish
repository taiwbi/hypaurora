# --- 2B Praise ---

function fish_greeting
    # Check if tput exists, stdout is a terminal, TERM is set and not 'dumb'
    if command -v tput >/dev/null; and set -q TERM; and test "$TERM" != dumb
        set -l term_width (tput cols) # -l for local scope

        # Display praise if terminal is wide enough
        if test $term_width -gt 35
            if test -x "$HOME/.config/fish/functions/praise.fish" # Check execute permission
                $HOME/.config/fish/functions/praise.fish
            else
                echo "Warning: Could not find executable praise.fish, check path/permissions."
            end
        end
    end
end
