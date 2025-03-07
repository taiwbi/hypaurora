alias artisan='php artisan'
alias sens='sensors && echo -e "\r\rNvidia GPU temp: "(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)"°C"'
alias vi=nvim

alias disable-proxy='unset ALL_PROXY all_proxy'
alias ls='lsd --group-directories-first'

alias cl='clear'
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

alias rm='rm -i'
alias mv='mv -i'
alias mkdir='mkdir -p'
alias df='df -h'
alias free='free -h'
alias aria='aria2c -x 16'

if [[ "$TERM" == "xterm-ghostty" || "$TERM" == "xterm-kitty" ]]; then
  alias icat='kitten icat'
fi

alias myip='curl --silent http://ip-api.com/json/ | jq'
ipinfo() { curl --silent "http://ip-api.com/json/$1" | jq; }

handle_tmux_session() {
  # Set the session name based on the current directory
  nv_dir_name=$(basename "$(/bin/pwd)")
  nv_dir_name=${nv_dir_name//./_}
  nv_session_name="TMX-$nv_dir_name"

  # Check if the tmux session already exists
  if tmux has-session -t "$nv_session_name" 2>/dev/null; then
    tmux attach -t "$nv_session_name"
  else
    # Create a new tmux session
    if ! tmux new -s "$nv_session_name" /bin/bash 2>/dev/null; then
      echo "Failed to create a new tmux session."
    fi
  fi

  # Kill the parent shell after tmux exits
  kill -9 $$
}
