#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Unset CDPATH, having it set messes up with script import paths
unset CDPATH

# The root of the checkout directory
export SRC_ROOT=$(cd "$(dirname "${BASH_SOURCE}")"/../.. && pwd -P)

# Add utilities
source "${SRC_ROOT}/scripts/lib/logging.sh"
# enable err trap handler
log::enable_errexit

source "${SRC_ROOT}/scripts/lib/utils.sh"
