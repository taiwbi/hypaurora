# Function to handle tmux session creation/attachment
function handle_tmux_session
    # Set the session name based on the current directory
    set nv_dir_name (basename (pwd))
    set nv_dir_name (echo $nv_dir_name | sed 's/\./_/g')
    set nv_session_name "TMX-$nv_dir_name"
    
    # Check if the tmux session already exists
    if tmux has-session -t $nv_session_name
        tmux attach -t $nv_session_name
    else
        # Create a new tmux session
        tmux new -s $nv_session_name 2> /dev/null
        or echo "Failed to create a new tmux session."
    end
    
    # Kill the parent shell after tmux exits
    kill -9 %self
end
