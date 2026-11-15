if not status is-interactive
    return
end
set -l state "$HOME/.local/state/dotfiles/fish-last-directory"
if set -q XDG_STATE_HOME
    set state "$XDG_STATE_HOME/dotfiles/fish-last-directory"
end
if test "$PWD" = "$HOME"; and test -f "$state"
    set -l previous (cat "$state")
    if test -d "$previous"
        cd "$previous"
    end
end
function __dotfiles_save_directory --on-event fish_exit --inherit-variable state
    mkdir -p (dirname "$state"); or return
    printf '%s\n' "$PWD" >"$state"
end
