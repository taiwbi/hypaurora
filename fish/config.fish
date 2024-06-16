if status is-interactive
  # Commands to run in interactive sessions can go here
  set -U EDITOR nvim
end

starship init fish | source
source $HOME/.config/fish/proxy.fish

for file in $HOME/.config/fish/functions/*.fish
  source "$file"
end

set fish_greeting ''
