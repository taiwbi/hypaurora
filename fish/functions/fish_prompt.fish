function fish_prompt
    # Colors
    set -l reset (set_color normal)
    set -l white (set_color white)
    set -l black (set_color black)
    set -l dim (set_color brblack)

    # Custom colors
    set -l red_bg (set_color -b red)
    set -l red_fg (set_color red)
    set -l blue_bg (set_color -b blue)
    set -l blue_fg (set_color blue)
    set -l cyan_bg (set_color -b cyan)
    set -l cyan_fg (set_color cyan)
    set -l magenta_bg (set_color -b magenta)
    set -l magenta_fg (set_color magenta)
    set -l green_bg (set_color -b green)
    set -l green_fg (set_color green)

    # Separator triangles (Powerline style)
    set -l sep_right ''  # Right-pointing triangle
    set -l sep_left ''   # Left-pointing triangle

    # Current directory
    set -l dir (basename (pwd))
    if test (pwd) = $HOME
        set dir "~"
    end

    # Git info
    set -l git_info ""
    if git rev-parse --git-dir >/dev/null 2>&1
        set -l branch (git symbolic-ref --short HEAD 2>/dev/null; or git rev-parse --short HEAD 2>/dev/null)
        if test -n "$branch"
            set -l dirty ""
            if not git diff --quiet 2>/dev/null; or not git diff --cached --quiet 2>/dev/null
                set dirty "*"
            end
            set git_info "$green_fg$sep_left$reset$green_bg$red_fg $black$branch$dirty$reset$green_fg$sep_right$reset"
        end
    end

    # Username@hostname
    set -l user_host "$USER@$hostname"

    # Terminal width for responsiveness
    set -l term_width (tput cols 2>/dev/null; or echo 80)

    # Build prompt segments
    set -l cat_segment "$red_fg$sep_left$red_bg$white🐱$reset$red_fg$sep_right$reset"
    set -l user_segment "$blue_fg$sep_left$blue_bg$black$user_host$reset$magenta_bg$blue_fg$sep_right$reset"
    set -l dir_segment "$magenta_bg$black $dir$reset$magenta_fg$sep_right$reset"

    # Calculate total length for responsiveness
    set -l prompt_len (string length -- "$cat_segment$user_segment$dir_segment")
    if test -n "$git_info"
        set prompt_len (math $prompt_len + (string length -- $git_info))
    end

    printf "%s %s%s " \
        $cat_segment \
        $user_segment  \
        $dir_segment
    if test -n "$git_info"
        printf $git_info
    end
    # If screen is too narrow, put command on new line
    if test $term_width -lt 50
        printf "\n󱞩 "
    else
        printf "  "
    end
end
