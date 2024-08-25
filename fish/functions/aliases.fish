#!/usr/bin/fish

alias 'idehelper' "php artisan ide-helper:models && php artisan ide-helper:generate && php artisan ide-helper:eloquent && php artisan ide-helper:meta"
alias vi nvim

alias ls 'ls --color --group-directories-first'

alias rm 'rm -i'
alias mv 'mv -i'
alias mkdir='mkdir -p'
alias df='df -h'
alias free='free -m'

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
