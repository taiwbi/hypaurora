# Native fish prompt with Powerline effects
function fish_prompt
    set -g _prompt_last_status $status
    printf '\e[?1004l'      # disable terminal focus reporting

    set -l reset (set_color normal)

    # Transient prompt handling
    if set -q _transient
        set -l symbol '❯'
        if test (id -u) -eq 0
            set symbol '#'
        end
        set -l prompt_color (set_color green)
        if test $_prompt_last_status -ne 0
            set prompt_color (set_color red)
        end
        echo -n " "$prompt_color$symbol$reset" "
        return
    end

    # Colors (using standard color names to support terminal themes)
    set -l BG_USER_ROOT red
    set -l BG_USER_SSH magenta
    set -l BG_DIR blue
    set -l BG_GIT_CLEAN green
    set -l BG_GIT_DIRTY yellow

    # Segment 1: User (if root or SSH)
    set -l user_seg ''
    set -l user_bg ''
    if test (id -u) -eq 0
        set user_seg " "(whoami)" "
        set user_bg $BG_USER_ROOT
    else if set -q SSH_CONNECTION; or set -q SSH_TTY; or set -q SSH_CLIENT
        set user_seg " "(whoami)"@"(prompt_hostname)" "
        set user_bg $BG_USER_SSH
    end

    # Segment 2: Directory
    set -l dir_seg " "(_prompt_pwd)" "
    set -l dir_bg $BG_DIR

    # Segment 3: Git
    set -l git_seg ''
    set -l git_bg ''
    set -l git_info (_prompt_git)
    set -l git_status $status
    if test $git_status -eq 0
        set git_seg " $git_info "
        set git_bg $BG_GIT_CLEAN
    else if test $git_status -eq 1
        set git_seg " $git_info "
        set git_bg $BG_GIT_DIRTY
    end

    # Assemble line 1 with powerline transitions
    set -l line ''
    if test -n "$user_seg"
        # Segment 1: User
        set line "$line"(set_color -b $user_bg white)"$user_seg"
        # Transition: User -> Dir
        set line "$line"(set_color -b $dir_bg $user_bg)""(set_color -b $dir_bg white)
    else
        # Start directly with Dir
        set line "$line"(set_color -b $dir_bg white)
    end

    # Segment 2: Dir
    set line "$line""$dir_seg"

    if test -n "$git_seg"
        # Transition: Dir -> Git
        # Green and Yellow backgrounds contrast best with black text
        set -l git_fg_text black
        set line "$line"(set_color -b $git_bg $dir_bg)""(set_color -b $git_bg $git_fg_text)
        # Segment 3: Git
        set line "$line""$git_seg"
        # End Git -> Default
        set line "$line"(set_color normal)(set_color $git_bg)""$reset
    else
        # End Dir -> Default
        set line "$line"(set_color normal)(set_color $dir_bg)""$reset
    end

    # Prompt symbol: ❯ colored green on success, red on failure
    set -l symbol '❯'
    if test (id -u) -eq 0
        set symbol '#'
    end
    set -l prompt_color (set_color green)
    if test $_prompt_last_status -ne 0
        set prompt_color (set_color red)
    end
    set -l prompt_char "$prompt_color$symbol$reset"

    # Print prompt
    if test "$COLUMNS" -lt 50
        printf '%s\n%s ' "$line" "$prompt_char"
    else
        printf '%s %s ' "$line" "$prompt_char"
    end

    set -g _prompt_ran 1
end

# Transient prompt logic
function transient_execute
    set -g _transient 1
    commandline -f repaint
    commandline -f execute
end

function _transient_clean --on-event fish_preexec
    set -e _transient
end

# Setup key bindings for transient prompt when the file is loaded
bind \r transient_execute 2>/dev/null
bind \n transient_execute 2>/dev/null
