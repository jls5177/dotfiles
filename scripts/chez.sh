#!/usr/bin/env bash

# enable unofficial bash strict mode
set -euo pipefail
IFS=$'\n\t'

SRC_ROOT=$(cd "$(dirname "${BASH_SOURCE}")"/.. && pwd -P)
SCRIPTS_ROOT=$(cd "$(dirname "${BASH_SOURCE}")" && pwd -P)
source "${SCRIPTS_ROOT}/lib/init.sh"

# Make sure common user bin directories are on the path
export PATH="$HOME/bin:$SRC_ROOT/bin:$PATH"

SECRETS="${SECRETS:-}"

# Setup source and config directory based on if Secrets is enabled or not
if [[ -z "${SECRETS}" ]]; then
    log::info "NOTE: Using default config"
    export SRC_DIR="${SRC_DIR:-$SRC_ROOT}"
    export CFG_FILE="${CFG_FILE:-$HOME/.config/chezmoi/jls5177-default/chezmoi.yaml}"
else
    log::info "NOTE: Using secrets config"
    export SRC_DIR="${SRC_DIR:-$SRC_ROOT}/secrets"
    export CFG_FILE="${CFG_FILE:-$HOME/.config/chezmoi/jls5177-secrets/chezmoi.yaml}"
fi

# run Chezmoi which picks up the EVs
. "${SCRIPTS_ROOT}/lib/run_chezmoi.sh"
