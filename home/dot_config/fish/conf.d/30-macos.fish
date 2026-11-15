if not status is-interactive
    return
end
alias o open
function pfd
    osascript -e 'tell application "Finder" to get POSIX path of (insertion location as alias)'
end
function cdf
    set -l directory (pfd); or return
    cd "$directory"
end
function listening
    if test (count $argv) -gt 1
        echo "Usage: listening [pattern]" >&2
        return 2
    end
    if test (count $argv) -eq 0
        sudo lsof -iTCP -sTCP:LISTEN -n -P
    else
        sudo lsof -iTCP -sTCP:LISTEN -n -P | grep -i --color -- "$argv[1]"
    end
end
function excuse
    if not command -q cowsay
        echo "excuse: install cowsay to display programming excuses" >&2
        return 127
    end
    "$HOME/.config/programmingexcuses/programmingexcuses" | cowsay
end
if command -q cowsay; and test -x "$HOME/.config/programmingexcuses/programmingexcuses"
    excuse
end
