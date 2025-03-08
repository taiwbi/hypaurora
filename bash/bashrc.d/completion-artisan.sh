#!/bin/bash
# Laravel Artisan Auto-Completion for Bash
# ---------------------------------------
# This script provides dynamic auto-completion for Laravel's `php artisan` commands in Bash.
#
# Requirements: Bash, Laravel project with `php artisan` available
# Author: taiwbi

_artisan_completion() {
  local cur commands cmd options fullcmd

  # Current word
  cur=${COMP_WORDS[COMP_CWORD]}

  # If completing the first argument after "php"
  if [ $COMP_CWORD -eq 1 ]; then
    if [[ $cur == art* ]]; then
      COMPREPLY=($(compgen -W "artisan" -- "$cur"))
    fi

    # If the first argument is "artisan", proceed with Artisan completion
  elif [ "${COMP_WORDS[1]}" == "artisan" ]; then

    # Case 1: No colon typed so far; complete the Artisan command normally.
    if [ $COMP_CWORD -eq 2 ]; then
      commands=$(php artisan list --raw | awk '{print $1}' | sed "s/:.*/:/" | uniq | tr '\n' ' ')
      COMPREPLY=($(compgen -W "$commands" -- "$cur"))

      # Case 2: Artisan command split because of colon, right after colon
    elif [ $COMP_CWORD -eq 3 ]; then
      local base="${COMP_WORDS[2]}"
      commands=$(php artisan list --raw | awk '{print $1}')
      local matches=$(echo "$commands" | grep -E "^${base}:")
      matches=$(echo "$matches" | sed "s/^${base}://")
      COMPREPLY=($(compgen -W "$matches"))

      # Case 3: Artisaan command split, completed something adter colon
    elif [ $COMP_CWORD -eq 4 ] && [[ "${COMP_WORDS[3]}" == ":" ]] ; then
      local base="${COMP_WORDS[2]}"
      local sub="${COMP_WORDS[3]}"
      local fullprefix="${base}${sub}"
      commands=$(php artisan list --raw | awk '{print $1}')
      commands=$(echo "$commands" | grep -E ".*:.*")
      # remove commands that are not in format *:*
      local matches=$(echo "$commands" | grep -E "^${fullprefix}")
      matches=$(echo "$matches" | sed "s/^${fullprefix}//")
      COMPREPLY=($(compgen -W "$matches" -- "$cur"))

      # Case 4: Completing options after a complete Artisan command.
    elif [ $COMP_CWORD -gt 4 ]; then
      fullcmd="${COMP_WORDS[2]}${COMP_WORDS[3]}${COMP_WORDS[4]}"
      notify-send "$fullcmd"
      if [[ $cur == -* ]]; then
        options=$(php artisan "$fullcmd" --help | sed -n '/Options:/,/^$/p' \
            | sed '1d;$d' \
            | while read -r line; do
            echo "$line" | sed 's/|/ /g' | sed 's/\[=.*\]/=/g' \
              | awk '{for(i=1;i<=NF;i++) if ($i ~ /^-/) print $i}'
        done | sort -u)
        COMPREPLY=($(compgen -W "$options" -- "$cur"))
      fi
    fi
  fi
}

# Register the completion function for the "php" command
complete -F _artisan_completion php
