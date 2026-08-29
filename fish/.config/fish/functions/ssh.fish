function ssh --wraps ssh --description 'kitten+ for ssh (nano support etc.)'
    if test "$TERM" = xterm-kitty; and command -q kitty
        command kitty +kitten ssh $argv
    else
        command ssh $argv
    end
end
