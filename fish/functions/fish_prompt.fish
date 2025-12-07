# Custom transient prompt setup
function __prompt_compact --description "Minimal prompt form for scrollback"
    set -l pink (set_color 'f472b6')
    set -l bold (set_color --bold)
    set -l reset (set_color normal)
    printf "%s " $bold$pink❯$reset
end

function __prompt_rich --description "Extended prompt form for the current command"
    # Modern vibrant color palette (using RGB for richer colors)
    set -l reset (set_color normal)
    set -l bold (set_color --bold)
    
    # Vibrant gradient-inspired colors
    set -l purple (set_color 'a78bfa')      # Soft purple
    set -l blue (set_color '60a5fa')        # Sky blue
    set -l cyan (set_color '22d3ee')        # Bright cyan
    set -l teal (set_color '2dd4bf')        # Teal
    set -l emerald (set_color '34d399')     # Emerald green
    set -l pink (set_color 'f472b6')        # Hot pink
    set -l orange (set_color 'fb923c')      # Vibrant orange
    set -l yellow (set_color 'fbbf24')      # Golden yellow
    set -l red (set_color 'f87171')         # Soft red
    set -l dim (set_color '6b7280')         # Muted gray
    
    # Powerline & Unicode symbols
    set -l sep ''                          # Right arrow separator
    set -l git_icon ''                     # Git branch icon
    set -l folder_icon ''                  # Folder icon
    set -l user_icon ''                    # User icon
    set -l prompt_char '❯'                  # Modern prompt character
    set -l dirty_icon '●'                   # Dirty indicator
    set -l clean_icon '✓'                   # Clean indicator

    # Current directory with smart truncation
    set -l dir (basename (pwd))
    if test (pwd) = $HOME
        set dir "~"
    else if test (string length $dir) -gt 25
        set dir (string sub -l 22 $dir)"..."
    end

    # Git info with enhanced status
    set -l git_info ""
    if git rev-parse --git-dir >/dev/null 2>&1
        set -l branch (git symbolic-ref --short HEAD 2>/dev/null; or git rev-parse --short HEAD 2>/dev/null)
        if test -n "$branch"
            # Check for changes
            set -l status_icon $clean_icon
            set -l status_color $emerald
            
            if not git diff --quiet 2>/dev/null; or not git diff --cached --quiet 2>/dev/null
                set status_icon $dirty_icon
                set status_color $orange
            end
            
            # Check for unpushed commits
            set -l unpushed ""
            set -l ahead (git rev-list --count @{upstream}..HEAD 2>/dev/null)
            if test -n "$ahead" -a "$ahead" -gt 0
                set unpushed " $cyan↑$ahead"
            end
            
            set git_info " $dim$sep $reset$pink$git_icon $bold$purple$branch $status_color$status_icon$unpushed$reset"
        end
    end

    # Username@hostname with icon
    set -l user_host "$USER@$hostname"

    # Terminal width for responsiveness
    set -l term_width (tput cols 2>/dev/null; or echo 80)

    # Build beautiful prompt segments
    set -l user_segment "$blue$user_icon $bold$cyan$user_host$reset"
    set -l dir_segment "$dim$sep $reset$teal$folder_icon $bold$emerald$dir$reset"

    # First line: user, directory, and git info
    printf "%s%s%s" \
        $user_segment \
        $dir_segment \
        $git_info
    
    # Second line or inline prompt character (responsive)
    if test $term_width -lt 85
        printf "\n$bold$pink$prompt_char$reset "
    else
        printf " $bold$pink$prompt_char$reset "
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