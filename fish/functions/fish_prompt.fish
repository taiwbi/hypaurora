function fish_prompt
    # Color definitions to match Starship colors
    set -l color_reset (set_color normal)
    set -l bright_white (set_color -o white)
    set -l black (set_color black)
    set -l red (set_color red)
    set -l green (set_color green)
    set -l blue (set_color -o blue)
    set -l fg1 (set_color red)      # fg:1 maps to red
    set -l fg9 (set_color brmagenta) # fg:9 maps to bright magenta
    
    # Get hostname (trim at .*.com pattern)
    set -l hostname_full (hostname)
    set -l hostname_display (string replace -r '\..*\.com$' '' $hostname_full)
    
    # SSH detection
    set -l ssh_symbol ""
    if set -q SSH_CLIENT; or set -q SSH_TTY; or string match -q "*ssh*" $TERM
        set ssh_symbol " SSH "
    end
    
    # Username styling
    set -l username_color $green
    if test (id -u) -eq 0
        set username_color (set_color -o red)  # root gets red bold
    end
    
    # Directory path with truncation
    set -l current_dir (pwd)
    set -l home_dir $HOME
    
    # Replace home directory with ~
    if string match -q "$home_dir*" $current_dir
        set current_dir (string replace $home_dir "~" $current_dir)
    end
    
    # Truncate directory path (keep last 3 components)
    set -l dir_parts (string split "/" $current_dir)
    set -l dir_count (count $dir_parts)
    
    if test $dir_count -gt 3
        set -l start_index (math $dir_count - 2)  # Keep last 3 parts
        set -l truncated_parts $dir_parts[$start_index..$dir_count]
        set current_dir "/"(string join "/" $truncated_parts)
    end
    
    # Git branch detection
    set -l git_branch ""
    set -l git_status_info ""
    
    if git rev-parse --git-dir >/dev/null 2>&1
        # Get current branch name
        set -l branch_name (git symbolic-ref --short HEAD 2>/dev/null; or git describe --tags --exact-match 2>/dev/null; or git rev-parse --short HEAD 2>/dev/null)
        
        if test -n "$branch_name"
            set git_branch "$fg1$color_reset$fg9$branch_name$color_reset"
        end
        
        # Git status information
        set -l git_status_output (git status --porcelain 2>/dev/null)
        set -l ahead_behind (git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
        
        set -l status_symbols ""
        
        # Check for various git statuses
        if test -n "$git_status_output"
            set -l has_staged false
            
            # Working tree changes (look at second character)
            if string match -q "* M *" $git_status_output
                set status_symbols "$status_symbols‌&" # Modified
            end
            if string match -q "* D *" $git_status_output
                set status_symbols "$status_symbols‌D" # Deleted
            end
            
            # Staging area changes (look at first character)  
            if string match -q "M *" $git_status_output
                set status_symbols "$status_symbols‌S" # Staged
                set has_staged true
            end
            if string match -q "A *" $git_status_output
                set status_symbols "$status_symbols‌N" # New Files
                set status_symbols "$status_symbols‌S" # Staged
                set has_staged true
            end
            if string match -q "D *" $git_status_output
                set status_symbols "$status_symbols‌N" # Staged
                set has_staged true
            end
            if string match -q "R *" $git_status_output
                set status_symbols "$status_symbols‌R" # Renamed
                set status_symbols "$status_symbols‌S" # Staged
                set has_staged true
            end
            if string match -q "C *" $git_status_output
                set status_symbols "$status_symbols‌S" # Staged
                set has_staged true
            end
            
            # Untracked files
            if string match -q "?? *" $git_status_output
                set status_symbols "$status_symbols‌U"
            end
        end
        
        # Ahead/behind information
        if test -n "$ahead_behind"
            set -l ahead (echo $ahead_behind | cut -f1)
            set -l behind (echo $ahead_behind | cut -f2)
            
            if test $ahead -gt 0
                set status_symbols "$status_symbols⭡$ahead"
            end
            
            if test $behind -gt 0
                set status_symbols "$status_symbols⭣$behind"
            end
        end
        
        if test -n "$status_symbols"
            set git_status_info "$fg1$status_symbols$color_reset"
        end
    end
    
    # Build the first line of the prompt
    set -l hostname_part "$blue$ssh_symbol$color_reset$green$hostname_display$color_reset"
    set -l username_part "$username_color"(whoami)"$color_reset"
    set -l directory_part "$black$current_dir$color_reset"
    
    set -l first_line "[$hostname_part@$username_part $directory_part]"
    
    # Add git information if available
    if test -n "$git_branch"
        set first_line "$first_line $git_branch"
    end
    
    if test -n "$git_status_info"
        set first_line "$first_line$git_status_info"
    end
    
    # Get terminal width
    set -l term_width (tput cols 2>/dev/null; or echo 80)
    
    # Calculate the visible length of the first line (strip color codes for length calculation)
    set -l first_line_visible (string replace -ra '\e\[[0-9;]*m' '' $first_line)
    set -l first_line_length (string length $first_line_visible)
    
    # Define threshold for line breaking (leave some margin for the # and input)
    set -l threshold (math $term_width - 90)
    
    # Output the prompt
    if test $first_line_length -gt $threshold
        # Two-line prompt for narrow terminals
        printf "%s\n%s#%s " $first_line $red $color_reset
    else
        # Single-line prompt for wide terminals
        printf "%s %s#%s " $first_line $red $color_reset
    end
end
