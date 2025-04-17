# ~/.config/fish/config.fish

# --- Environment Variables ---

fish_add_path $HOME/.local/bin $HOME/.local/binary

# Starship prompt configuration variable
set -gx STARSHIP_CONFIG "$HOME/.config/starship.toml" # -g for global, -x for export

# --- Automatic Proxy Setup (from setup.sh) ---
if functions -q set_proxy
    set_proxy
end

# --- Source Custom Configuration Snippets ---
for rc in ~/.config/fish/conf.d/*.fish
    source "$rc"
end

# --- Initializations (towards the end) ---

# Starship prompt init
starship init fish | source

# Source Fish Vim bindings if you use them
if status is-interactive
    fish_vi_key_bindings
end
