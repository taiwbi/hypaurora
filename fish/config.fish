set -gx EDITOR '/usr/bin/nvim'
set -gx OPENAI_API_KEY 'null' # Nothing for now :)
set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/gcr/ssh"

set -gx STARSHIP_CONFIG "$HOME/.config/starship.toml"

starship init fish | source
source $HOME/.config/fish/proxy.fish
source $HOME/.config/fish/fishmarks/marks.fish
source /etc/grc.fish

for file in $HOME/.config/fish/functions/*.fish
  source "$file"
end

set fish_greeting ''

if status is-interactive
  and not set -q argv[1]
  and not set -q TMUX
  and set -q NVIM
  exec tmux
end
