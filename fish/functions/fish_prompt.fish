function fish_prompt
    # Minimal color palette
    set -l reset (set_color normal)
    set -l blue (set_color blue)
    set -l cyan (set_color cyan)
    set -l yellow (set_color yellow)
    set -l red (set_color red)
    set -l dim (set_color brblack)
    
    # Current directory (just basename, or ~ for home)
    set -l dir (basename (pwd))
    if test (pwd) = $HOME
        set dir "~"
    end
    
    # Git branch if in repo
    set -l git_branch ""
    if git rev-parse --git-dir >/dev/null 2>&1
        set -l branch (git symbolic-ref --short HEAD 2>/dev/null; or git rev-parse --short HEAD 2>/dev/null)
        if test -n "$branch"
            # Simple dirty check
            set -l dirty ""
            if not git diff --quiet 2>/dev/null; or not git diff --cached --quiet 2>/dev/null
                set dirty "*"
            end
            set git_branch " $dim($yellow$branch$red$dirty$dim)$reset"
        end
    end
    
    # SSH indicator
    set -l ssh ""
    if set -q SSH_CLIENT; or set -q SSH_TTY
        set ssh "$dim ssh$reset "
    end
    
    # Build prompt: [ssh] dir (branch*) $
    printf "%s%s%s%s%s \$ " $ssh $blue $dir $reset $git_branch
end
