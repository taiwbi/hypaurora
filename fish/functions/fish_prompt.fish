# Native fish prompt
function fish_prompt
    set -g _prompt_last_status $status
    printf '\e[?1004l'      # disable terminal focus reporting

    set -l reset (set_color normal)

    # Transient prompt handling
    if set -q _transient
        set -e _transient
        set -l symbol '$'
        if test (id -u) -eq 0
            set symbol '#'
        end
        set -l prompt_color (set_color green)
        if test $_prompt_last_status -ne 0
            set prompt_color (set_color red)
        end
        echo -n $prompt_color$symbol$reset" "
        return
    end

    # Colors (using standard color names to support terminal themes)
    set -l color_user_root red
    set -l color_user_ssh magenta
    set -l color_dir blue
    set -l color_git_clean green
    set -l color_git_dirty yellow

    set -l prompt_text ''

    # Segment 1: User (only if root or SSH)
    if test (id -u) -eq 0
        set prompt_text (set_color $color_user_root)(whoami)$reset" "
    else if set -q SSH_CONNECTION; or set -q SSH_TTY; or set -q SSH_CLIENT
        set prompt_text (set_color $color_user_ssh)(whoami)"@"(prompt_hostname)$reset" "
    end

    # Segment 2: Directory
    set prompt_text "$prompt_text"(set_color $color_dir)(_prompt_pwd)$reset

    # Segment 3: Git
    set -l git_info (_prompt_git)
    set -l git_status $status
    if test $git_status -eq 0
        set prompt_text "$prompt_text" (set_color $color_git_clean)$git_info$reset
    else if test $git_status -eq 1
        set prompt_text "$prompt_text" (set_color $color_git_dirty)$git_info$reset
    end

    # Prompt symbol: $ colored green on success, red on failure
    set -l symbol '$'
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
        printf '%s\n%s ' "$prompt_text" "$prompt_char"
    else
        printf '%s %s ' "$prompt_text" "$prompt_char"
    end

    set -g _prompt_ran 1
end

# Transient prompt logic
function transient_execute
    if commandline --paging-mode
        commandline -f execute
        return
    end

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
