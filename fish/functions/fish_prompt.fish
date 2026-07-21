# Native fish prompt
function fish_prompt
    set -g _prompt_last_status $status
    set -e _pager_exec  # clear stale flag from pager accept-without-execute
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

    # Save prompt visible width for ANSI transient redraw in fish_preexec
    set -l stripped_text (string replace -ra '\e\[[^m]*m' '' -- "$prompt_text")
    set -l stripped_len (string length -- "$stripped_text")
    if test "$COLUMNS" -lt 50
        set -g _prompt_extra_lines 1
        set -g _prompt_last_line_width 2  # "$ "
    else
        set -g _prompt_extra_lines 0
        set -g _prompt_last_line_width (math "$stripped_len + 3")  # "text $ "
    end

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
    # Never show transient prompt on an empty command line
    set -l cmdline_text (string join \n -- (commandline))
    if test -z "(string trim -- $cmdline_text)"
        commandline -f execute
        return
    end

    # In paging mode we can't tell if Enter will execute or just accept a
    # completion.  Skip the repaint-based transient here and let fish_preexec
    # handle it retroactively with ANSI codes if the command really executes.
    if commandline --paging-mode
        set -g _pager_exec 1
        commandline -f execute
        return
    end

    set -e _pager_exec
    set -g _transient 1
    commandline -f repaint
    commandline -f execute
end

function _transient_preexec --on-event fish_preexec
    # Normal transient (non-pager path) — flag was already consumed by
    # the repaint in transient_execute, just clean up.
    set -e _transient

    # Pager path: the command was executed from pager mode.  The full prompt
    # is still on screen.  Overwrite it with the transient prompt using ANSI
    # escape sequences.
    if not set -q _pager_exec
        return
    end
    set -e _pager_exec

    set -l symbol '$'
    test (id -u) -eq 0; and set symbol '#'
    set -l pc (set_color green)
    test $_prompt_last_status -ne 0; and set pc (set_color red)
    set -l reset (set_color normal)

    # Calculate how many terminal rows the old prompt + command occupied
    set -l cmd_vis_len (string length -- $argv[1])
    set -l last_line_chars (math "$_prompt_last_line_width + $cmd_vis_len")
    set -l last_line_rows (math "ceil($last_line_chars / $COLUMNS)")
    set -l total_up (math "$_prompt_extra_lines + $last_line_rows")

    # Move cursor up, go to column 1, clear to end of screen, print transient
    printf '\e[%dA\r\e[J%s%s%s %s\n' $total_up $pc $symbol $reset $argv[1]
end

# Setup key bindings for transient prompt when the file is loaded
bind \r transient_execute 2>/dev/null
bind \n transient_execute 2>/dev/null
