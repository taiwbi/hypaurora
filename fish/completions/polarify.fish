# ~/.config/fish/completions/polarify.fish
# polarify completions for Fish shell
# Grammar:
#   polarify list
#   polarify preview <theme> [options]
#   polarify apply <theme> [options]

complete -c polarify -f

# --- Theme discovery --------------------------------------------------------
function __theme_manager_themes
    set -l dir ~/Documents/hypaurora/themes
    if not test -d $dir
        echo wallpaper
        return
    end
    for f in $dir/*.json
        if test -f $f
            echo (basename $f .json)
        end
    end
    echo wallpaper
end

function __polarify_seen_theme
    for t in (commandline -opc)
        if contains -- $t (__theme_manager_themes)
            return 0
        end
    end
    return 1
end

function __polarify_selected_theme_is
    set -l needle $argv[1]
    for t in (commandline -opc)
        if test "$t" = "$needle"
            return 0
        end
    end
    return 1
end

function __polarify_arg_contains
    set -l needle $argv[1]
    for t in (commandline -opc)
        if test "$t" = "$needle"
            return 0
        end
    end
    return 1
end

# --- Subcommands ------------------------------------------------------------
complete -c polarify -n "__fish_use_subcommand" -a "list" -d "List theme"
complete -c polarify -n "__fish_use_subcommand" -a "preview" -d "Preview theme"
complete -c polarify -n "__fish_use_subcommand" -a "apply" -d "Apply theme"

# --- preview: theme first, then options -------------------------------------
complete -c polarify -n "__fish_seen_subcommand_from preview; and not __polarify_seen_theme" \
    -a "(__theme_manager_themes)" -d "Theme name"

# (example option for preview, add more if needed)
complete -c polarify -n "__fish_seen_subcommand_from preview; and __polarify_seen_theme; and not __fish_seen_argument --dry-run" \
    -l dry-run -d "Show what would be done without previewing"

# --- apply: theme first, then options ---------------------------------------
complete -c polarify -n "__fish_seen_subcommand_from apply; and not __polarify_seen_theme" \
    -a "(__theme_manager_themes)" -d "Theme name"

# --listen: only for wallpaper, mutually exclusive with --dry-run, no dupes
complete -c polarify -n "__fish_seen_subcommand_from apply; and __polarify_seen_theme; and __polarify_selected_theme_is wallpaper; and not __polarify_arg_contains --dry-run; and not __fish_seen_argument --listen" \
    -l listen -d "Watch wallpaper file for changes"

# --dry-run: only if not already given and not with --listen
complete -c polarify -n "__fish_seen_subcommand_from apply; and __polarify_seen_theme; and not __polarify_arg_contains --listen; and not __fish_seen_argument --dry-run" \
    -l dry-run -d "Show what would be done without applying"

# --variant: only once
complete -c polarify -n "__fish_seen_subcommand_from apply; and __polarify_seen_theme; and not __fish_seen_argument --variant" \
    -l variant -xa "dark light" -d "Theme variant (for wallpaper)"

# --- Global help ------------------------------------------------------------
complete -c polarify -s h -l help -d "Show help message"
