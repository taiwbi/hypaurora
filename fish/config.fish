# ~/.config/fish/config.fish

# --- Environment Variables ---

fish_add_path $HOME/.local/bin $HOME/.local/binary
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

# --- Startship ---
starship init fish | source

# Disable focus reporting
functions -c fish_prompt __starship_fish_prompt

function fish_prompt
    printf '\e[?1004l'
    __starship_fish_prompt $argv
end

function starship_transient_prompt_func
    set_color red
    echo -n '○ '
    set_color normal
end

enable_transience
