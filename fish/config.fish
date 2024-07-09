set -gx EDITOR '/usr/bin/nvim'
set -gx OPENAI_API_KEY 'null' # Nothing for now :)
set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/gcr/ssh"

starship init fish | source
source $HOME/.config/fish/proxy.fish

for file in $HOME/.config/fish/functions/*.fish
  source "$file"
end

set PATH $HOME/.local/bin  $PATH

set fish_greeting ''
