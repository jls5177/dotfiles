if not status is-interactive
    return
end
function checkMidwaySession
    set -l tool "$HOME/.config/alfred/Alfred.alfredpreferences/workflows/user.workflow.861E084F-E815-46A8-8636-F9E8829F93DF/amazon-alfred-workflow-beta2"
    if not test -x "$tool"
        echo "checkMidwaySession: install the Amazon Alfred workflow first" >&2
        return 127
    end
    "$tool" midway-session-valid
end
if test -x "$HOME/.config/alfred/Alfred.alfredpreferences/workflows/user.workflow.861E084F-E815-46A8-8636-F9E8829F93DF/amazon-alfred-workflow-beta2"
    checkMidwaySession
end
