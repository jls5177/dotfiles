#!/usr/bin/env bash

# enable unofficial bash strict mode
set -euo pipefail
IFS=$'\n\t'

# source the init script
SRC_ROOT=$(cd "$(dirname "${BASH_SOURCE}")"/../.. && pwd -P)
SCRIPTS_ROOT=$(cd "$(dirname "${BASH_SOURCE}")"/.. && pwd -P)
source "${SCRIPTS_ROOT}/lib/init.sh"

# Linux on Go likes to install into the local directory
export PATH="$HOME/bin:$SRC_ROOT/bin:$PATH"

REINIT="${REINIT:-false}"
DRYRUN="${DRYRUN:-false}"

DATA="${DATA:-}"

SRC_DIR="${SRC_DIR:-}"
CFG_DIR="${CFG_FILE:-}"
DST_DIR="${DST_DIR:-}"

CMD="${1:-}"
if [[ -z "${CMD}" ]]; then
  log::error_exit "No command specified, cannot execute Chezmoi"
fi

# TODO: add support to pass in other arguments
EXTRA_ARGS=""

# build the list of arguments to pass to Chezmoi
args=()

if [[ "${CMD}" == "init" ]]; then
  if [[ "$REINIT" == "true" ]]; then
    args+=("--data=false")
  elif [[ -n "$DATA" ]]; then
    args+=("--data=$DATA")
  fi
fi

# Default to this source directory if another directory is not provided
if [[ -n "${SRC_DIR}" ]]; then
  args+=("--source" "${SRC_DIR}")
else
  args+=("--source" "${SRC_ROOT}")
fi

# Chezmoi will default to using "~/.config/chezmoi/chezmoi.[yaml|toml|json]"
if [[ -n "${CFG_DIR}" ]]; then
  args+=("--config" "${CFG_DIR}")
  if [[ "${CMD}" == "init" ]]; then
    # Init requires the templated config-path to also be defined
    args+=("--config-path" "${CFG_DIR}")
  fi
fi

# Chezmoi will default to $HOME
if [[ -n "${DST_DIR}" ]]; then
  args+=("--destination" "${DST_DIR}")
fi

# enable debug and verbose logs if VERBOSE is set to a non-zero value
if [[ $VERBOSE -ge 1 ]]; then
  args+=("--debug")
  if [[ $VERBOSE -ge 2 ]]; then
    args+=("--verbose")
  fi
fi

if [[ "${DRYRUN}" == "true" ]]; then
  arg_str="${args[@]}"
  log::status "DRYRUN" "$(ansi --green "chezmoi ${CMD} ${arg_str}")"
else
  chezmoi "${CMD}" "${args[@]}"
fi
