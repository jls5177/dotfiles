function wd --description "Persist named directory bookmarks"
    set -l root "$HOME/.local/state/dotfiles/warps"
    if set -q XDG_STATE_HOME
        set root "$XDG_STATE_HOME/dotfiles/warps"
    end
    set -l action "$argv[1]"
    set -l name "$argv[2]"
    if not contains -- "$action" add rm list
        set name "$action"
    end
    if test "$action" != list; and not string match -qr '^[A-Za-z0-9_.-]+$' -- "$name"
        echo "Usage: wd add <name> | wd rm <name> | wd list | wd <name>" >&2
        return 2
    end
    switch "$action"
        case add
            mkdir -p "$root"; or return
            printf '%s\n' "$PWD" >"$root/$name"
        case rm
            command rm -- "$root/$name"
        case list
            for entry in "$root"/*
                printf '%s -> %s\n' (basename "$entry") (cat "$entry")
            end
        case '*'
            if not test -f "$root/$name"
                echo "wd: unknown bookmark: $name" >&2
                return 1
            end
            cd (cat "$root/$name")
    end
end
