#!/usr/bin/env bash

# enable unofficial bash strict mode
set -euo pipefail
IFS=$'\n\t'

SCRIPTS_ROOT=$(cd "$(dirname "${BASH_SOURCE}")" && pwd -P)
source "${SCRIPTS_ROOT}/lib/init.sh"

log::info "HOST_OS=$(util::host_os)"
if [[ "$(util::host_os)" == "darwin"* ]]; then
    if util::is_available brew; then
        ansi --yellow "Homebrew is installed. Skipping"
    else
        ansi --green "Homebrew not installed. Installing..."
        curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | sh
    fi
    if util::is_available chezmoi; then
        ansi --yellow "Chezmoi is installed. Skipping"
    else
        ansi --green "Chezmoi not installed. Installing..."
        brew install chezmoi
    fi
	# util::is_available brew ||
	# 	curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh
	# util::is_available chezmoi || brew install chezmoi
elif [[ "$(util::host_os)" == "linux"* ]]; then
    ansi --yellow "Warning Linux support is untested."
     if util::is_available chezmoi; then
        ansi --yellow "Chezmoi is installed. Skipping"
    else
        ansi --green "Chezmoi not installed. Installing..."
        sh -c "$(wget -qO- https://chezmoi.io/get)" || sh -c "$(curl -fsLS https://chezmoi.io/get)"
    fi
fi
