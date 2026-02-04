# --- Aliases (can also go in conf.d/aliases.fish) ---
# Keep simple aliases here or move them to conf.d/

alias fastfetch 'fastfetch --gpu-hide-type integrated'
alias ff 'fastfetch'

alias vi nvim
alias cl clear
alias cd.. 'cd ..'
alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'
alias ..... 'cd ../../../..'
alias ...... 'cd ../../../../..'

# Interactive aliases (safety)
alias rm 'rm -i'
alias mv 'mv -i'
alias cp 'cp -i' # Added common one
alias mkdir 'mkdir -p'

# Proxy aliases
alias disable-proxy 'set -e http_proxy; set -e HTTP_PROXY; set -e https_proxy; set -e HTTPS_PROXY; set -e ftp_proxy; set -e FTP_PROXY; set -e all_proxy; set -e ALL_PROXY; set -e no_proxy; set -e NO_PROXY'

# Utility Aliases
alias ls 'lsd --group-directories-first -F'
alias df 'df -h'
alias free 'free -m' # Use -m for megabytes (or -h for human) like original free='free -h'
alias aria 'disable-proxy; aria2c -x 16'
alias sens 'sensors; and printf "\\r\\rNvidia GPU temp: %s°C\\n" (nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)' # Use printf and ;and

function ariap
    # Strip the protocol prefix (e.g., "socks5://") from the variable
    set -l proxy_host (string replace -r '.*//' '' -- "$ALL_PROXY")

    # Run aria2c with the cleaned proxy and forward all other arguments
    aria --all-proxy="$proxy_host" $argv
end

# PHP/Laravel Aliases
alias artisan 'php artisan'
alias ide-helper 'php artisan ide-helper:models --nowrite; and php artisan ide-helper:generate; and php artisan ide-helper:eloquent; and php artisan ide-helper:meta' # Use ;and
alias sail 'sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'

# IP Aliases
alias myip 'curl --silent http://ip-api.com/json/ | jq'

# Conditional Aliases (Example: icat)
if test "$TERM" = "xterm-ghostty" -o "$TERM" = "xterm-kitty"
    if command -v kitten >/dev/null
        alias icat 'kitten icat'
    end
end

if test "$TERM" = "xterm-kitty"
    alias ssh 'kitten ssh'
end
