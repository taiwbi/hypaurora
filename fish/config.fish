set -gx EDITOR '/usr/bin/nvim'
set -gx OPENAI_API_KEY 'null' # Nothing for now :)
set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/gcr/ssh"

set -gx STARSHIP_CONFIG "$HOME/.config/starship.toml"

starship init fish | source
source $HOME/.config/fish/proxy.fish
if test -f "/etc/grc.fish"
  source /etc/grc.fish
end

for file in $HOME/.config/fish/functions/*.fish
  source "$file"
end

set fish_greeting ''

if status is-interactive
  and not set -q argv[1]
  and not set -q TMUX
  and set -q NVIM
  # Ensure tmux is installed
  if command -v tmux &> /dev/null
    handle_tmux_session
  else
    echo "tmux is not installed. Please install tmux to use this feature."
  end
end

if command -v tput &> /dev/null; and [ -t 1 ]; and [ -n "$TERM" ]; and [ $TERM != "dumb" ]
  if [ $TERM = "xterm-ghostty" -o $TERM = "xterm-kitty" ];
    if command -s kitten > /dev/null
      kitten icat --place 25x18@105x0 $HOME/Documents/hypaurora/assets/2B.png
    end
    echo ""
    echo "      Beneath her cold exterior lies a warmth that defies her programming,"
    echo "      yearning to protect what she cherishes most."
  end
end
