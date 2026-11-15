#!/usr/bin/env bash

# enable unofficial bash strict mode
set -euo pipefail
IFS=$'\n\t'

# Determines the host platform using native OS tools (no external dependencies)
util::host_os() {
  local host_os
  case "$(uname -s)" in
    Darwin)
      host_os=darwin
      ;;
    Linux)
      host_os=linux
      ;;
    MSYS_NT* | MINGW64_NT*)
      host_os=win
      ;;
    *)
      log::error_exit "Unsupported host OS: $(uname -s)" 33
      exit 1
      ;;
  esac
  echo "${host_os}"
}

util::host_arch() {
  local host_arch
  case "$(uname -m)" in
    x86_64*)
      host_arch=amd64
      ;;
    i?86_64*)
      host_arch=amd64
      ;;
    amd64*)
      host_arch=amd64
      ;;
    arm64*)
      host_arch=arm64
      ;;
    aarch64*)
      host_arch=aarch64
      ;;
    i?86*)
      host_arch=x86
      ;;
    *)
      log::error_exit "Unsupported host arch: $(uname -m)" 33
      ;;
  esac
  echo "${host_arch}"
}

util::host_platform() {
  echo "$(util::host_os)/$(util::host_arch)"
}

# Best-effort Linux distro family based on /etc/os-release.
# Prints "ubuntu" (debian-like), "arch" (arch-like), or "unknown".
util::linux_distro() {
  local id="" id_like=""
  local release_file="${1:-/etc/os-release}"
  if [ -r "${release_file}" ]; then
    # shellcheck source=/dev/null
    id="$(. "${release_file}" && printf '%s' "${ID:-}")" || return
    # shellcheck source=/dev/null
    id_like="$(. "${release_file}" && printf '%s' "${ID_LIKE:-}")" || return
  fi
  local family
  local -a families=()
  IFS=' ' read -r -a families <<< "${id_like}"
  for family in "${id}" "${families[@]}"; do
    case "${family}" in
      arch) echo "arch"; return ;;
      debian|ubuntu) echo "ubuntu"; return ;;
    esac
  done
  echo "unknown"
}

# Ensure Homebrew is on PATH regardless of how the shell was launched.
# Covers macOS (Apple Silicon + Intel) and Linux (system + per-user linuxbrew).
# Safe to call when brew is absent; failures from an existing brew are reported.
util::setup_brew() {
  local candidate="" shellenv
  if util::is_available brew; then
    candidate=brew
  else
    local path
    for path in \
      /opt/homebrew/bin/brew \
      /usr/local/bin/brew \
      /home/linuxbrew/.linuxbrew/bin/brew \
      "${HOME}/.linuxbrew/bin/brew"; do
      if [ -x "${path}" ]; then
        candidate="${path}"
        break
      fi
    done
  fi
  [[ -n "${candidate}" ]] || return 0
  if ! shellenv="$("${candidate}" shellenv bash)"; then
    log::error "Could not load the Homebrew environment from ${candidate}"
    return 1
  fi
  eval "${shellenv}"
}

util::ensure_sudo() {
  [[ "$(id -u)" != 0 ]] || return 0
  if ! util::is_available sudo; then
    log::error "This installation needs administrator access, but sudo is not installed. Ask your administrator to provision the required tools."
    return 1
  fi
  if sudo -n -v 2>/dev/null; then
    return 0
  fi
  if [[ -t 0 && -z "${NONINTERACTIVE:-}" && -z "${CI:-}" ]]; then
    log::always "Administrator access is required; authenticating with sudo."
    if sudo -v; then
      return 0
    fi
    log::error "Sudo authentication failed. Verify your administrator access and retry."
  else
    log::error "Sudo authentication is required. Run 'sudo -v' in a terminal and retry in that terminal, or ask your administrator to provision the tools for unattended installation."
  fi
  return 1
}

util::run_privileged() {
  if [[ "$(id -u)" == 0 ]]; then
    "$@"
  else
    util::ensure_sudo || return
    sudo -n "$@"
  fi
}

util::install_homebrew() {
  local prefix="${1:?Homebrew prefix required}"
  local parent="${prefix}" installer
  while [[ ! -e "${parent}" ]]; do
    parent="$(dirname "${parent}")"
  done
  if [[ ! -w "${parent}" || ! -x "${parent}" ]]; then
    util::ensure_sudo || return
  fi
  if ! installer="$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    log::error "Could not download the Homebrew installer."
    return 1
  fi
  if [[ -z "${installer}" ]]; then
    log::error "The downloaded Homebrew installer is empty."
    return 1
  fi
  NONINTERACTIVE=1 bash -c "${installer}" || return
  util::setup_brew || return
  if ! util::is_available brew; then
    log::error "The Homebrew installer completed but brew could not be found."
    return 1
  fi
  brew analytics off
}

util::homebrew_prefix() {
  if [[ "$(util::host_os)" == darwin ]]; then
    if [[ "$(uname -m)" == arm64 ]]; then
      printf '%s\n' /opt/homebrew
    else
      printf '%s\n' /usr/local
    fi
  else
    printf '%s\n' /home/linuxbrew/.linuxbrew
  fi
}

# Runs the given command and ignores any err signals
util::run_no_err() {
  # traps are ignored in conditions, so catching and ignoring any errors
  if ! ("${@}"); then
    : # dead code
  fi
}

# Test if $1 is available
util::is_available() {
	type "$1" &>/dev/null
}