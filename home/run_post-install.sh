#!/usr/bin/env bash

# enable unofficial bash strict mode
set -euo pipefail
IFS=$'\n\t'

SRC_DIR="${SRC_DIR:-}"
CFG_DIR="${CFG_FILE:-}"

# Use Chezmoi to get source root as it runs the script from temp files
HOME_ROOT=$(chezmoi --source "${SRC_DIR}" --config "${CFG_DIR}" source-path)
SRC_ROOT=$(cd "${HOME_ROOT}"/.. && pwd -P)
source "${SRC_ROOT}/scripts/common.sh"

log::status "Running post install"

cd "${SRC_ROOT}" && make post-chezmoi
