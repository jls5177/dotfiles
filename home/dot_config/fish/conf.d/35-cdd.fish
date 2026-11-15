if not status is-interactive
    return
end
if not set -q CDD_HOST
    set -gx CDD_HOST simoju-scm-4x-al2-clouddesk.aka.corp.amazon.com
end
for operation in add_dir remove_dir sync exec
    function cdd_$operation --inherit-variable operation
        set -l tool "$HOME/.config/zsh/dev-tool"
        if set -q DEV_TOOL_BIN
            set tool "$DEV_TOOL_BIN"
        end
        if not test -x "$tool"
            echo "cdd: install dev-tool and set DEV_TOOL_BIN to its executable path" >&2
            return 127
        end
        switch "$operation"
            case add_dir
                "$tool" cdd add --dir "$argv[1]" --cdd-host "$CDD_HOST" --remote-root /tmp/../
            case remove_dir
                "$tool" cdd remove --dir "$argv[1]" --cdd-host "$CDD_HOST"
            case sync
                "$tool" cdd sync --dir "$argv[1]"
            case exec
                "$tool" cdd exec -- $argv
        end
    end
end
