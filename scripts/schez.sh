#!/usr/bin/env bash

# enable unofficial bash strict mode
set -euo pipefail
IFS=$'\n\t'

SCRIPTS_ROOT=$(cd "$(dirname "${BASH_SOURCE}")" && pwd -P)

export SECRETS=1
. "${SCRIPTS_ROOT}/chez.sh"
