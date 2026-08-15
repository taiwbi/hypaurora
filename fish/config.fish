# ~/.config/fish/config.fish

# --- Environment Variables ---

fish_add_path $HOME/.local/bin $HOME/.local/binary $HOME/.config/composer/vendor/bin $HOME/.npm-global/bin
fish_add_path ~/.cargo/bin

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

bind alt-backspace backward-kill-word
