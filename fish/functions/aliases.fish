#!/usr/bin/fish

alias 'laravel-idehelper' "php artisan ide-helper:models --nowrite && php artisan ide-helper:generate && php artisan ide-helper:eloquent && php artisan ide-helper:meta"
alias sens 'sensors && echo -e "\r\rNvidia GPU temp: "(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)"°C"'
alias vi nvim

alias ls 'lsd --group-directories-first'

alias rm 'rm -i'
alias mv 'mv -i'
alias mkdir='mkdir -p'
alias df='df -h'
alias free='free -h'
alias aria='aria2c -x 16'

if [ $TERM = "xterm-ghostty" -o $TERM = "xterm-kitty" ];
  alias icat='kitten icat'
end

function ipinfo
  curl --silent "http://ipinfo.io/$argv[1]/json" | jq
end

function myip
  curl --silent "http://ip-api.com/json" | jq
end

function wrnd
  set number (random 1 $argv[1])

  set integer_result (math "$number" / "4" | awk '{print int($1)}')
  set remainder_result (math "$number" % "4")

  echo "Integer result: $integer_result"
  echo "Remainder result: $remainder_result"
end
