#!/usr/bin/env fish

sleep 0.15
if command -v tput > /dev/null; and test -n "$TERM"; and test "$TERM" != "dumb"
    set term_width (tput cols)
    set wrap_width $term_width

    if test "$TERM" = "xterm-ghostty"; or test "$TERM" = "xterm-kitty"
        if command -v kitten > /dev/null 2>&1; and test "$term_width" -gt 40
            set position (math $term_width - 21)
            kitten icat -n --place "20x14@$position"x0 "$HOME/Documents/hypaurora/assets/2B.png"
            
            set wrap_width (math $term_width - 22)
        end
    end

    if test "$term_width" -gt 35
        tput cr
        shuf -n 1 "$HOME/Documents/hypaurora/assets/2BPraise.txt" | fmt -w "$wrap_width"
    end
end
