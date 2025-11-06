# Custom transient prompt setup
function __prompt_compact --description "Minimal prompt form for scrollback"
    printf "%s " (set_color red)\$ (set_color normal)
end

function __prompt_rich --description "Extended prompt form for the current command"
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
            set git_info "$red_fg $green_fg$branch$dirty$reset"
        end
    end

    # Username@hostname
    set -l user_host "$USER@$hostname"

    # Terminal width for responsiveness
    set -l term_width (tput cols 2>/dev/null; or echo 80)

    # Build prompt segments
    set -l user_segment "$blue_fg$user_host$reset"
    set -l dir_segment "$magenta_fg$dir$reset"

    # Calculate total length for responsiveness
    set -l prompt_len (string length -- "$user_segment$dir_segment")
    if test -n "$git_info"
        set prompt_len (math $prompt_len + (string length -- $git_info))
    end

    printf "%s %s " \
        $user_segment  \
        $dir_segment
    if test -n "$git_info"
        printf $git_info
    end
    # If screen is too narrow, put command on new line
    if test $term_width -lt 85
        printf "\n$red_fg\$ $reset"
    else
        printf " $red_fg\$ $reset"
    end
end

function fish_prompt --description 'Write out the prompt'
    if test "$TRANSIENT" = transient
        __prompt_compact
        echo -en \e\[0J # Clear from cursor to end of screen (handles multi-line prompts)
        set --global TRANSIENT normal
        return 0
    else
        __prompt_rich
    end
end

# Key binding handlers for transient behavior
function __transient_execute
    commandline --function expand-abbr suppress-autosuggestion
    if commandline --is-valid || test -z "$(commandline)"
        if commandline --paging-mode && test -n "$(commandline)"
            commandline -f accept-autosuggestion
            return 0
        end
        set --global TRANSIENT transient
        commandline --function repaint execute
        return 0
    end
    commandline -f execute
end

function __transient_ctrl_c_execute
    if test "$(commandline --current-buffer)" = ""
        commandline --function cancel-commandline
        return 0
    end
    set --global TRANSIENT transient
    commandline --function repaint cancel-commandline kill-inner-line repaint-mode repaint
end

function __transient_ctrl_d_execute
    if test "$(commandline --current-buffer)" != ""
        return 0
    end
    set --global TRANSIENT transient
    commandline --function repaint exit
end

# Bindings
bind --user --mode default \r __transient_execute
bind --user --mode insert \r __transient_execute
bind --user --mode default \cj __transient_execute
bind --user --mode insert \cj __transient_execute
bind --user --mode default \cd __transient_ctrl_d_execute
bind --user --mode insert \cd __transient_ctrl_d_execute
bind --user --mode default \cc __transient_ctrl_c_execute
bind --user --mode insert \cc __transient_ctrl_c_execute