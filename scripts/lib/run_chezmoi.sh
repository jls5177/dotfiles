#!/usr/bin/env bash

# enable unofficial bash strict mode
set -euo pipefail
IFS=$'\n\t'

# source the init script
SRC_ROOT=$(cd "$(dirname "${BASH_SOURCE}")"/../.. && pwd -P)
SCRIPTS_ROOT=$(cd "$(dirname "${BASH_SOURCE}")"/.. && pwd -P)
source "${SCRIPTS_ROOT}/lib/init.sh"
source "${SCRIPTS_ROOT}/lib/age_unlock.sh"

# Linux on Go likes to install into the local directory
export PATH="$HOME/bin:$SRC_ROOT/bin:$PATH"

REINIT="${REINIT:-false}"
DRYRUN="${DRYRUN:-false}"

DATA="${DATA:-}"

SRC_DIR="${SRC_DIR:-}"
CFG_DIR="${CFG_FILE:-}"
DST_DIR="${DST_DIR:-}"

CMD="${1:-}"
shift
if [[ -z "${CMD}" ]]; then
  log::error_exit "No command specified, cannot execute Chezmoi"
fi

# build the list of arguments to pass to Chezmoi
args=("$CMD")

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
  effective_cfg="${CFG_DIR}"

  # For commands that must decrypt secrets, unlock the passphrase-protected age
  # identity once and point chezmoi at the plaintext identity so it does not
  # prompt per encrypted file. A throwaway config is used so the committed config
  # keeps referencing the encrypted key (raw chezmoi on a new machine still works).
  if [[ "${CMD}" != "init" ]] && [[ "${DRYRUN}" != "true" ]] && age::should_unlock "${CMD}"; then
    enc_identity="$(awk -F'"' '/^[[:space:]]*identity:/ {print $2; exit}' "${CFG_DIR}")"
    if [[ -n "${enc_identity}" ]]; then
      trap age::cleanup EXIT
      unlocked_id="$(age::unlock_identity "${enc_identity}")" \
        || log::error_exit "Could not unlock age-encrypted secrets"
      # Register in this (parent) shell so the EXIT trap can shred it; the
      # registration inside the command substitution above ran in a subshell.
      age::_register_tmpfile "${unlocked_id}"
      tmp_cfg="$(mktemp "${TMPDIR:-/tmp}/chezmoi-cfg.XXXXXX")"
      age::_register_tmpfile "${tmp_cfg}"
      sed "s#^\([[:space:]]*identity:[[:space:]]*\).*#\1\"${unlocked_id}\"#" \
        "${CFG_DIR}" > "${tmp_cfg}"
      effective_cfg="${tmp_cfg}"
      # The temp config has no recognizable extension, so tell chezmoi its format
      # (derived from the real config's extension; defaults to yaml).
      cfg_fmt="${CFG_DIR##*.}"
      case "${cfg_fmt}" in
        yaml|yml) cfg_fmt="yaml" ;;
        toml|json) ;;
        *) cfg_fmt="yaml" ;;
      esac
      args+=("--config-format" "${cfg_fmt}")
      # Preserve the real persistent state (run_once/run_onchange) when overriding.
      args+=("--persistent-state" "$(dirname "${CFG_DIR}")/chezmoistate.boltdb")
    fi
  fi

  args+=("--config" "${effective_cfg}")
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

args=("${args[@]}" "$@")

if [[ "${DRYRUN}" == "true" ]]; then
  arg_str="${args[@]}"
  log::status "DRYRUN" "$(ansi --green "chezmoi ${arg_str}")"
else
  chezmoi "${args[@]}"
fi
