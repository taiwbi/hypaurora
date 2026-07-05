function __fish_sail_artisan_commands_with_descriptions
    # Use the local sail if it exists
    set -l sail_cmd "./vendor/bin/sail"
    if not test -f $sail_cmd
        set sail_cmd "sail"
    end
    begin
        $sail_cmd artisan list --raw 2>/dev/null
        or return
    end | grep -vE '^ ' | string replace -r '\s+' '\t'
end

function __fish_sail_artisan_commands
    __fish_sail_artisan_commands_with_descriptions | cut -f 1
end

function __fish_sail_use_artisan_subcommand
    set -l tokens (commandline -opc)
    if test (count $tokens) -eq 2
        and string match -q -r '^(sail|.*/sail)$' "$tokens[1]"
        and string match -q -r '^(artisan|debug)$' "$tokens[2]"
        return 0
    end
    return 1
end

function __fish_sail_seen_artisan_help
    set -l tokens (commandline -opc)
    if test (count $tokens) -eq 3
        and string match -q -r '^(sail|.*/sail)$' "$tokens[1]"
        and string match -q -r '^(artisan|debug)$' "$tokens[2]"
        and test "$tokens[3]" = "help"
        return 0
    end
    return 1
end

set -l sail_commands up stop restart ps artisan php composer node npm npx pnpm pnpx yarn bun bunx mysql mariadb psql mongodb redis valkey debug test phpunit pest pint dusk dusk:fails shell bash root-shell root-bash tinker share open bin run build

set -l sail_descriptions \
    "Start the application" \
    "Stop the application" \
    "Restart the application" \
    "Display the status of all containers" \
    "Run an Artisan command" \
    "Run a PHP command" \
    "Run a Composer command" \
    "Run a Node command" \
    "Run a npm command" \
    "Run a npx command" \
    "Run a pnpm command" \
    "Run a pnpx command" \
    "Run a Yarn command" \
    "Run a bun command" \
    "Run a bunx command" \
    "Start a MySQL CLI session" \
    "Start a MariaDB CLI session" \
    "Start a PostgreSQL CLI session" \
    "Start a Mongo Shell session" \
    "Start a Redis CLI session" \
    "Start a Valkey CLI session" \
    "Run an Artisan command in debug mode" \
    "Run PHPUnit tests via Artisan" \
    "Run PHPUnit" \
    "Run Pest" \
    "Run Pint" \
    "Run Dusk tests" \
    "Re-run failed Dusk tests" \
    "Start a container shell session" \
    "Start a container bash session" \
    "Start a container root shell" \
    "Start a container root bash" \
    "Start a Laravel Tinker session" \
    "Share the application publicly" \
    "Open the site in your browser" \
    "Run Composer binary scripts" \
    "Run a command in container" \
    "Rebuild the Sail containers"

for cmd in sail ./vendor/bin/sail
    # Check if 'artisan' file exists in current directory before offering completions
    for i in (seq (count $sail_commands))
        complete -c $cmd -f -n 'test -f artisan; and __fish_use_subcommand' -a $sail_commands[$i] -d $sail_descriptions[$i]
    end
    complete -c $cmd -f -n 'test -f artisan; and __fish_sail_use_artisan_subcommand' -a '(__fish_sail_artisan_commands_with_descriptions)'
    complete -c $cmd -f -n 'test -f artisan; and __fish_sail_seen_artisan_help' -a '(__fish_sail_artisan_commands)'
end
