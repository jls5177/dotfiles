#!/usr/bin/env bash

# Common utilities, variables and checks for all build scripts.
set -o errexit
set -o nounset
set -o pipefail

# Unset CDPATH, having it set messes up with script import paths
unset CDPATH

# The root of the checkout directory
export SRC_ROOT=$(cd "$(dirname "${BASH_SOURCE}")"/.. && pwd -P)

source "${SRC_ROOT}/scripts/lib/init.sh"

# Log the host platform for easy debugging
host_platform=$(util::host_platform)
log::info "Detected platform: $host_platform"
