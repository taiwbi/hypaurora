# Shorten the working directory: /home/mahdi/Documents/Projects/x -> ~/D/P/x
function _prompt_pwd
    set -l path $PWD
    if test "$path" = "$HOME"
        echo '~'
        return
    else if string match -q -- "$HOME/*" "$path"
        set path '~/'(string sub -s (math (string length -- "$HOME") + 2) -- "$path")
    end

    set -l parts (string split / -- $path)
    set -l n (count $parts)
    set -l out
    for i in (seq $n)
        set -l p $parts[$i]
        if test $i -eq $n
            set -a out $p
        else if test -z "$p"
            set -a out ''
        else if string match -qr '^\.' -- "$p"
            set -a out (string sub -l 2 -- "$p")
        else
            set -a out (string sub -l 1 -- "$p")
        end
    end
    string join / -- $out
end
