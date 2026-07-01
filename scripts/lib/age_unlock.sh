#!/usr/bin/env bash

# Helpers to unlock the passphrase-protected age identity once per chezmoi run.
#
# chezmoi invokes `age` once per encrypted file, and age prompts for the
# passphrase every time. To avoid that, we decrypt the passphrase-protected
# identity a single time into an ephemeral plaintext identity and point chezmoi
# at it, so the rest of the run needs no prompts. The plaintext identity is
# shredded on exit.

# Track temp files so they can be shredded on exit.
_AGE_UNLOCK_TMPFILES=()

age::_register_tmpfile() {
  _AGE_UNLOCK_TMPFILES+=("$1")
}

# Shred and remove every temp file registered during this run.
age::cleanup() {
  local f
  for f in "${_AGE_UNLOCK_TMPFILES[@]:-}"; do
    [[ -n "${f}" && -e "${f}" ]] && { rm -P "${f}" 2>/dev/null || rm -f "${f}"; }
  done
  _AGE_UNLOCK_TMPFILES=()
}

# age::unlock_identity <encrypted-identity-path>
# Decrypts the passphrase-protected identity into a fresh 0600 plaintext file and
# echoes its path. Prompts once for the passphrase via age's own TTY prompt.
# NOTE: the caller must pass the returned path to age::_register_tmpfile so the
# EXIT trap can shred it (this function typically runs in a command-substitution
# subshell, where its own registration would not survive).
age::unlock_identity() {
  local enc="${1:?encrypted identity path required}"
  if [[ ! -f "${enc}" ]]; then
    log::error "age identity not found: ${enc}"
    return 1
  fi
  if ! util::is_available age; then
    log::error "age is not installed (needed to unlock secrets); run 'make install-tools'"
    return 1
  fi

  local idfile
  idfile="$(mktemp "${TMPDIR:-/tmp}/chezmoi-age-id.XXXXXX")" || return 1
  chmod 600 "${idfile}"

  log::info "Unlocking age identity (enter passphrase once)" >&2
  if ! age -d -o "${idfile}" "${enc}" </dev/tty; then
    rm -f "${idfile}"
    log::error "failed to unlock age identity"
    return 1
  fi

  printf '%s' "${idfile}"
}

# age::should_unlock <chezmoi-command>
# True for commands that read encrypted source state (so we unlock once instead
# of prompting per-file), or whenever CHEZ_DECRYPT=1 is set (e.g. status-secrets).
age::should_unlock() {
  local cmd="${1:-}"
  if [[ "${CHEZ_DECRYPT:-0}" == "1" ]]; then
    return 0
  fi
  case "${cmd}" in
    apply|diff|cat) return 0 ;;
    *) return 1 ;;
  esac
}
