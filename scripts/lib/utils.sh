#!/usr/bin/env bash

# Common utilities, variables and checks for all build scripts.
set -o errexit
set -o nounset
set -o pipefail

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

# Runs the given command and ignores any err signals
util::run_no_err() {
  # traps are ignored in conditions, so catching and ignoring any errors
  if ! ("${@}"); then
    : # dead code
  fi
}
