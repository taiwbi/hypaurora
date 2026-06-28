# Emit the git segment. Silent if there is no git command or the current
# directory is not a repository.
# Returns exit code:
#   0: Clean repository
#   1: Dirty repository
#   2: Not a repository
function _prompt_git
    command -q git; or return 2
    set -l branch (git symbolic-ref --short -q HEAD 2>/dev/null)
    if test -z "$branch"
        set branch (git rev-parse --short HEAD 2>/dev/null)
    end
    test -z "$branch"; and return 2

    set -l ahead 0
    set -l behind 0
    set -l staged 0
    set -l modified 0
    set -l untracked 0

    set -l info (git status --porcelain --branch 2>/dev/null)
    for line in $info
        if string match -q -- '## *' "$line"
            set -l m (string match -r 'ahead ([0-9]+)' -- "$line")
            test (count $m) -ge 2; and set ahead $m[2]
            set m (string match -r 'behind ([0-9]+)' -- "$line")
            test (count $m) -ge 2; and set behind $m[2]
        else if string match -qr '^\?\?' -- "$line"
            set untracked 1
        else
            set -l x (string sub -s 1 -l 1 -- "$line")
            set -l y (string sub -s 2 -l 1 -- "$line")
            if test "$x" != ' '; and test "$x" != '?'
                set staged 1
            end
            test "$y" != ' '; and set modified 1
        end
    end

    set -l st ''
    test "$ahead" -gt 0; and set st "$st⇡$ahead"
    test "$behind" -gt 0; and set st "$st⇣$behind"
    test "$staged" -eq 1; and set st "$st+"
    test "$modified" -eq 1; and set st "$st!"
    test "$untracked" -eq 1; and set st "$st?"

    set -l out " $branch"
    if test -n "$st"
        set out "$out $st"
    end
    echo -n "$out"

    if test "$staged" -eq 1; or test "$modified" -eq 1; or test "$untracked" -eq 1
        return 1
    else
        return 0
    end
end
