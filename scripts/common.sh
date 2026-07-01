#!/usr/bin/env bash

# enable unofficial bash strict mode
set -euo pipefail
IFS=$'\n\t'

# Unset CDPATH, having it set messes up with script import paths
unset CDPATH

# The root of the checkout directory
export SRC_ROOT=$(cd "$(dirname "${BASH_SOURCE}")"/.. && pwd -P)

source "${SRC_ROOT}/scripts/lib/init.sh"

# Ensure Homebrew is on PATH for the scripts chezmoi runs (esp. Linux linuxbrew,
# which lives at /home/linuxbrew/.linuxbrew and is otherwise not on PATH).
util::setup_brew

# Log the host platform for easy debugging
host_platform=$(util::host_platform)
log::info "Detected platform: $host_platform"
