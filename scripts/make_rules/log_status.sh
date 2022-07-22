#!/usr/bin/env bash

# enable unofficial bash strict mode
set -euo pipefail
IFS=$'\n\t'

# source the init script
SCRIPTS_ROOT=$(cd "$(dirname "${BASH_SOURCE}")"/.. && pwd -P)
source "${SCRIPTS_ROOT}/lib/init.sh"

CMD="${1:-}"
if [[ -z "${CMD}" ]]; then
  log::error_exit "No log command specified"
fi
shift

if [[ "${CMD}" == "status" ]]; then
  echo ""
  log::status "$@"
elif [[ "${CMD}" == "info" ]]; then
  LVL=0 log::level::log "$@"
else
  LVL=1 log::debug "$@"
fi
