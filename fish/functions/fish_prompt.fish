# Native fish prompt
function fish_prompt
    set -g _prompt_last_status $status
    printf '\e[?1004l'      # disable terminal focus reporting

    set -l reset (set_color normal)
    set -l line ''

    # Username: only for root (red) or over SSH (user@host).
    if test (id -u) -eq 0
        set line $line(set_color red)(whoami)$reset' '
    else if set -q SSH_CONNECTION; or set -q SSH_TTY; or set -q SSH_CLIENT
        set line $line(whoami)'@'(prompt_hostname)' '
    end

    set line "$line"(set_color brblue)(_prompt_pwd)"$reset"

    # Capture git separately: an empty command substitution concatenated
    # inline would blank out the whole string, so join via a quoted variable.
    set -l git (_prompt_git)
    set line "$line$git"

    if test "$COLUMNS" -lt 50
        printf '%s\n$ ' $line
    else
        printf '%s $ ' $line
    end

    set -g _prompt_ran 1
end
