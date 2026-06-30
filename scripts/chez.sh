#!/usr/bin/env bash

# enable unofficial bash strict mode
set -euo pipefail
IFS=$'\n\t'

SRC_ROOT=$(cd "$(dirname "${BASH_SOURCE}")"/.. && pwd -P)
SCRIPTS_ROOT=$(cd "$(dirname "${BASH_SOURCE}")" && pwd -P)
source "${SCRIPTS_ROOT}/lib/init.sh"

# Make sure common user bin directories are on the path
export PATH="$HOME/bin:$SRC_ROOT/bin:/opt/homebrew/bin:$PATH"

# Single environment: secrets are encrypted in-repo with age (see home/key.txt.age)
export SRC_DIR="${SRC_DIR:-$SRC_ROOT}"
export CFG_FILE="${CFG_FILE:-$HOME/.config/chezmoi/jls5177-default/chezmoi.yaml}"

# run Chezmoi which picks up the EVs
. "${SCRIPTS_ROOT}/lib/run_chezmoi.sh" "$@"
