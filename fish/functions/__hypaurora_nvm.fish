function __hypaurora_nvm --description 'Run Bash nvm and import its shell environment'
    if not test -s "$NVM_DIR/nvm.sh"
        printf 'nvm: cannot find %s/nvm.sh\n' "$NVM_DIR" >&2
        return 127
    end

    set -l state_file (command mktemp)
    or return 1

    # Keep command output on the terminal. Only NUL-delimited environment data
    # goes through the temporary file; arguments and values are never evaluated.
    command bash --noprofile --norc -c '
        state_file=$1
        mode=$2
        shift 2
        . "$NVM_DIR/nvm.sh" --no-use
        case "$mode" in
            init)
                { [[ "$(nvm version default)" != system ]] && nvm use --silent default; } >/dev/null 2>&1 ||
                    nvm use --silent node >/dev/null 2>&1 || true
                ;;
            run)
                nvm "$@"
                ;;
            complete)
                [[ -s "$NVM_DIR/bash_completion" ]] || exit 0
                . "$NVM_DIR/bash_completion"
                COMP_WORDS=("$@")
                COMP_CWORD=$((${#COMP_WORDS[@]} - 1))
                __nvm
                printf "%s\n" "${COMPREPLY[@]}"
                exit 0
                ;;
        esac
        result=$?
        for name in PATH MANPATH NVM_BIN NVM_INC; do
            printf "%s\0%s\0" "$name" "${!name-}"
        done > "$state_file"
        exit "$result"
    ' hypaurora-nvm "$state_file" $argv
    set -l result $status

    while read -lz name; and read -lz value
        if test -n "$value"
            # Fish automatically splits PATH and MANPATH on colons.
            set -gx $name "$value"
        else
            set -eg $name
        end
    end < "$state_file"
    command rm -f -- "$state_file"
    return $result
end
