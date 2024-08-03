set -gx EDITOR '/usr/bin/nvim'
set -gx OPENAI_API_KEY 'null' # Nothing for now :)
set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/gcr/ssh"

set THEME_MODE $(gsettings get org.gnome.desktop.interface color-scheme)
if [ "$THEME_MODE" = "'prefer-dark'" ]
  export STARSHIP_CONFIG="$HOME/.config/fish/starship-dark.toml"
else
  export STARSHIP_CONFIG="$HOME/.config/fish/starship.toml"
end

starship init fish | source
source $HOME/.config/fish/proxy.fish
source $HOME/.config/fish/fishmarks/marks.fish

for file in $HOME/.config/fish/functions/*.fish
  source "$file"
end

set fish_greeting ''
