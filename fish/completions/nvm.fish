# Reuse nvm-sh's installed completion definitions, including local aliases.
complete -c nvm -f -a '(__hypaurora_nvm complete (commandline -opc) (commandline -ct))' -n 'test -s "$NVM_DIR/nvm.sh"; and test -s "$NVM_DIR/bash_completion"'
