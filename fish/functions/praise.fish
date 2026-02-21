#!/usr/bin/env fish

set term_width (tput cols)
set wrap_width (math $term_width - 20)

tput cr
shuf -n 1 "$HOME/Documents/hypaurora/assets/2BPraise.txt" | fmt -w "$wrap_width"
