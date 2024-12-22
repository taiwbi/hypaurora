set -gx EDITOR '/usr/bin/nvim'
set -gx OPENAI_API_KEY 'null' # Nothing for now :)
set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/gcr/ssh"

set -gx STARSHIP_CONFIG "$HOME/.config/starship.toml"

starship init fish | source
source $HOME/.config/fish/proxy.fish
source /etc/grc.fish

for file in $HOME/.config/fish/functions/*.fish
  source "$file"
end

set fish_greeting ''

# Open tmux in neovim terminal
if status is-interactive
  and not set -q argv[1]
  and not set -q TMUX
  and set -q NVIM

  # Ensure tmux is installed
  if not command -v tmux &> /dev/null
    echo "tmux is not installed. Please install tmux to use this feature."
    return 1
  end

  # Set the session name based on the current directory
  set nv_dir_name (basename (pwd))
  set nv_session_name "TMX-$nv_dir_name"

  # Check if the tmux session already exists
  if tmux has-session -t $nv_session_name
    tmux attach -t $nv_session_name
  else
    # Create a new tmux session
    tmux new -s $nv_session_name 2> /dev/null
    if test $status -ne 0
      echo "Failed to create a new tmux session."
      return 1
    end
  end
end
