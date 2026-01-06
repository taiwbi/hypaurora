# fish prompt port of the provided Bash prompt

set -g __prompt_last_status 0
set -g fish_prompt_pwd_dir_length 0
set -g VIRTUAL_ENV_DISABLE_PROMPT 1

function __prompt_save_status --on-event fish_postexec
    set -g __prompt_last_status $status
end

function __prompt_glyphs --description 'Set prompt glyph variables'
    set -l mode unicode
    if set -q PROMPT_GLYPHS
        set mode $PROMPT_GLYPHS
    end

    if test "$mode" = "ascii"
        set -g GLY_OK     "ok"
        set -g GLY_FAIL   "!!"
        set -g GLY_BRANCH "git:"
        set -g GLY_DIRTY  "*"
        set -g GLY_PROMPT ">"
    else
        set -g GLY_OK     "✔"
        set -g GLY_FAIL   "✘"
        set -g GLY_BRANCH ""
        set -g GLY_DIRTY  "●"
        set -g GLY_PROMPT "❯"
    end
end

function __prompt_git --description 'Print git branch + dirty marker (leading space), or nothing'
    type -q git; or return 0
    command git rev-parse --is-inside-work-tree >/dev/null 2>&1; or return 0

    set -l branch (command git symbolic-ref --quiet --short HEAD 2>/dev/null)
    if test -z "$branch"
        set branch (command git rev-parse --short HEAD 2>/dev/null)
    end
    test -n "$branch"; or return 0

    set -l dirty ""

    command git diff --quiet --ignore-submodules -- 2>/dev/null; or set dirty "$GLY_DIRTY"
    command git diff --cached --quiet --ignore-submodules -- 2>/dev/null; or set dirty "$GLY_DIRTY"

    set -l untracked (command git ls-files --others --exclude-standard 2>/dev/null | head -n 1)
    if test -n "$untracked"
        set dirty "$GLY_DIRTY"
    end

    echo -n "$GLY_BRANCH $branch$dirty"
end

function __prompt_venv --description 'Print python venv (leading space), or nothing'
    set -q VIRTUAL_ENV; or return 0
    set -l name (basename -- "$VIRTUAL_ENV")
    echo -n "($name)"
end

function __is_ssh --description 'Return success if in an SSH session'
    set -q SSH_CLIENT; and return 0
    set -q SSH_TTY; and return 0
    set -q SSH_CONNECTION; and return 0
    return 1
end

function fish_prompt
    # Agent mode: keep it intentionally minimal
    if test "$ANTIGRAVITY_AGENT" = "1"
        echo -n '$ '
        return
    end

    __prompt_glyphs

    set -l last_status $__prompt_last_status

    set -l cwd (basename (pwd))
    set -l git (__prompt_git)
    set -l venv (__prompt_venv)

    set -l ssh_indicator ""
    if __is_ssh
        set ssh_indicator "󰛳 ssh "
    end

    # Status indicator
    set -l status_symbol ""
    set -l status_color ""
    if test $last_status -eq 0
        set status_symbol "$GLY_OK"
        set status_color (set_color green)
    else
        set status_symbol "$GLY_FAIL $last_status"
        set status_color (set_color red)
    end

    # Prompt character: root vs user
    set -l prompt_char "$GLY_PROMPT"
    if test (id -u) -eq 0
        set prompt_char "#"
    end

    # Normal: two-line prompt
    # Line 1: status + user@host + cwd + git + venv
    # Line 2: prompt symbol
    printf '%s%s%s%s %s%s%s %s%s %s%s %s%s\n%s%s%s ' \
        (set_color --dim) "$ssh_indicator" \
        $status_color "$status_symbol" \
        (set_color green) "$USER@$hostname" (set_color normal) \
        (set_color blue) "$cwd" \
        (set_color yellow) "$git" \
        (set_color magenta) "$venv" \
        $status_color"$prompt_char" (set_color normal)
end
