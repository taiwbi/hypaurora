set -U EDITOR '/usr/bin/nvim'
set -U OPENAI_API_KEY '' # Nothing for now :)

starship init fish | source
source $HOME/.config/fish/proxy.fish

for file in $HOME/.config/fish/functions/*.fish
  source "$file"
end

set fish_greeting ''
