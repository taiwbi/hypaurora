# ~/.config/fish/config.fish

# --- Environment Variables ---

fish_add_path $HOME/.local/bin $HOME/.local/binary

# --- Automatic Proxy Setup (from setup.sh) ---
if functions -q set_proxy
    set_proxy
end

# --- Source Custom Configuration Snippets ---
for rc in ~/.config/fish/conf.d/*.fish
    source "$rc"
end

# --- Configuration Options ---
set -g fish_features '!'bracketed-paste

# disable terminal focus reporting (DEC private mode 1004)
printf '\e[?1004l'
