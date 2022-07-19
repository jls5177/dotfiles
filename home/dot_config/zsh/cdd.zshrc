#!/usr/bin/env bash

# The root of the build/dist directory
DEV_TOOL_BIN="$(cd "$(dirname "${BASH_SOURCE}")" && pwd -P)"/dev-tool

#export CDD_HOST=${CDD_HOST:-simoju-clouddesk.aka.corp.amazon.com}
export CDD_HOST=${CDD_HOST:-simoju-scm-4x-al2-clouddesk.aka.corp.amazon.com}
#export CDD_HOST=${CDD_HOST:-dev-dsk-simoju-2a-d3235f40.us-west-2.amazon.com}

# 1) Start a sync session for current working directory
cdd_add_dir() {
    $DEV_TOOL_BIN cdd add --dir $1 --cdd-host $CDD_HOST --remote-root "/tmp/../"
}

# 2) Stop a sync session
cdd_remove_dir() {
    $DEV_TOOL_BIN cdd remove --dir $1 --cdd-host $CDD_HOST
}

# 3) Force a sync
cdd_sync() {
    $DEV_TOOL_BIN cdd sync --dir $1
}

cdd_exec() {
    $DEV_TOOL_BIN cdd exec -- $@
}
