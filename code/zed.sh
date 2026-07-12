#!/bin/bash

export CLAUDE_CODE_EXECUTABLE="$HOME/.npm-global/bin/claude"
export DEVSENSE_PHP_LS_LICENSE;
DEVSENSE_PHP_LS_LICENSE="$(cat "$HOME/.keys/DEVSENSE")"

zed "$@"
