# In config.fish or conf.d/bookmarks.fish
set -g FISHMARKS_FILE "$HOME/.local/share/fishmarks" # Use fish standard location if possible
# Ensure directory exists (runs once per shell start if in config.fish)
mkdir -p (dirname $FISHMARKS_FILE)
touch $FISHMARKS_FILE
