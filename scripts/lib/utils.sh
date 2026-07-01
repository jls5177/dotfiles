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

# Ensure Homebrew is on PATH regardless of how the shell was launched.
# Covers macOS (Apple Silicon + Intel) and Linux (system + per-user linuxbrew).
# Safe to call when brew is absent (no-op); returns 0 either way.
util::setup_brew() {
  # Already on PATH -> make sure the full env is loaded and return.
  if util::is_available brew; then
    eval "$(brew shellenv)"
    return 0
  fi

  local candidate
  for candidate in \
    /opt/homebrew/bin/brew \
    /usr/local/bin/brew \
    /home/linuxbrew/.linuxbrew/bin/brew \
    "${HOME}/.linuxbrew/bin/brew"; do
    if [ -x "${candidate}" ]; then
      eval "$("${candidate}" shellenv)"
      return 0
    fi
  done
  return 0
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