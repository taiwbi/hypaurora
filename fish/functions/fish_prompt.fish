function fish_prompt
    # Color definitions - minimal and clean palette
    set -l color_reset (set_color normal)
    set -l color_user (set_color cyan)
    set -l color_root (set_color -o red)
    set -l color_host (set_color blue)
    set -l color_dir (set_color brblack)
    set -l color_git_branch (set_color magenta)
    set -l color_git_dirty (set_color yellow)
    set -l color_git_clean (set_color green)
    set -l color_prompt (set_color red)
    
    # Get username
    set -l username (whoami)
    set -l username_color $color_user
    if test (id -u) -eq 0
        set username_color $color_root  # root gets red bold
    end
    
    # Get hostname (trim at .*.com pattern)
    set -l hostname_full (hostname)
    set -l hostname_display (string replace -r '\..*\.com$' '' $hostname_full)
    
    # SSH detection - add icon if in SSH session
    set -l ssh_prefix ""
    if set -q SSH_CLIENT; or set -q SSH_TTY; or string match -q "*ssh*" $TERM
        set ssh_prefix " "  # Nerd font SSH icon
    end
    
    # Directory path with smart truncation
    set -l current_dir (pwd)
    set -l home_dir $HOME
    
    # Replace home directory with ~
    if string match -q "$home_dir*" $current_dir
        set current_dir (string replace $home_dir "~" $current_dir)
    end
    
    # Truncate directory path (keep last 3 components)
    set -l dir_parts (string split "/" $current_dir)
    set -l dir_count (count $dir_parts)
    
    if test $dir_count -gt 4
        set -l start_index (math $dir_count - 2)  # Keep last 3 parts
        set -l truncated_parts $dir_parts[$start_index..$dir_count]
        set current_dir "…/"(string join "/" $truncated_parts)
    end
    
    # Git information
    set -l git_info ""
    
    if git rev-parse --git-dir >/dev/null 2>&1
        # Get current branch name or commit
        set -l branch_name (git symbolic-ref --short HEAD 2>/dev/null; \
            or git describe --tags --exact-match 2>/dev/null; \
            or git rev-parse --short HEAD 2>/dev/null)
        
        if test -n "$branch_name"
            # Git status check
            set -l is_dirty false
            set -l status_symbols " "
            
            # Check if working tree is dirty
            if not git diff --quiet 2>/dev/null; or not git diff --cached --quiet 2>/dev/null
                set is_dirty true
            end
            
            # Check for untracked files
            if test (git ls-files --others --exclude-standard | wc -l) -gt 0
                set is_dirty true
                set status_symbols "$status_symbols"  # Untracked files icon
            end
            
            # Check for staged changes
            if not git diff --cached --quiet 2>/dev/null
                set status_symbols "$status_symbols"  # Staged changes icon
            end
            
            # Check for unstaged changes
            if not git diff --quiet 2>/dev/null
                set status_symbols "$status_symbols"  # Modified files icon
            end
            
            # Check for stashes
            if test (git stash list | wc -l) -gt 0
                set status_symbols "$status_symbols"  # Stash icon
            end
            
            # Check ahead/behind status
            set -l upstream (git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
            if test -n "$upstream"
                set -l ahead_behind (git rev-list --left-right --count HEAD...$upstream 2>/dev/null)
                if test -n "$ahead_behind"
                    set -l ahead (echo $ahead_behind | cut -f1)
                    set -l behind (echo $ahead_behind | cut -f2)
                    
                    if test $ahead -gt 0
                        set status_symbols "$status_symbols$ahead"  # Ahead icon
                    end
                    
                    if test $behind -gt 0
                        set status_symbols "$status_symbols$behind"  # Behind icon
                    end
                end
            end
            
            # Set git color based on status
            set -l git_color $color_git_clean
            if test $is_dirty = true
                set git_color $color_git_dirty
            end
            
            # Build git info string
            set git_info " $color_git_branch $branch_name$git_color$status_symbols$color_reset"
        end
    end
    
    # Build the prompt components
    set -l user_host "$ssh_prefix$username_color$username$color_reset@$color_host$hostname_display$color_reset"
    set -l directory "$color_dir$current_dir$color_reset"
    
    # Combine all parts
    set -l prompt_line "$user_host $directory$git_info"
    
    # Get terminal width
    set -l term_width (tput cols 2>/dev/null; or echo 80)
    
    # Calculate the visible length (strip color codes)
    set -l prompt_visible (string replace -ra '\e\[[0-9;]*m' '' $prompt_line)
    set -l prompt_length (string length $prompt_visible)
    
    # Add some buffer for the prompt symbol and user input
    set -l threshold (math $term_width - 80)
    
    # Output the prompt with responsive line breaking
    if test $prompt_length -gt $threshold
        # Two-line prompt for narrow terminals
        printf "%s\n%s❯%s " $prompt_line $color_prompt $color_reset
    else
        # Single-line prompt for wide terminals
        printf "%s %s❯%s " $prompt_line $color_prompt $color_reset
    end
end