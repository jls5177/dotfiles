#!/usr/bin/env bash

# enable unofficial bash strict mode
set -euo pipefail
IFS=$'\n\t'

SRC_ROOT=$(cd "$(dirname "${BASH_SOURCE}")"/.. && pwd -P)
SCRIPTS_ROOT=$(cd "$(dirname "${BASH_SOURCE}")" && pwd -P)
source "${SCRIPTS_ROOT}/lib/init.sh"

# Make sure common user bin directories are on the path
export PATH="$HOME/bin:$SRC_ROOT/bin:/opt/homebrew/bin:$PATH"

log::info "HOST_OS=$(util::host_os)"
if [[ "$(util::host_os)" == "darwin"* ]]; then
    # install homebrew
    if util::is_available brew; then
        ansi --yellow "Homebrew is installed. Skipping"
    else
        ansi --green "Homebrew not installed. Installing..."
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        brew analytics off
    fi

    # Install Chezmoi
    if util::is_available chezmoi; then
        ansi --yellow "Chezmoi is installed. Skipping"
    else
        ansi --green "Chezmoi not installed. Installing..."
        brew install chezmoi
    fi

    # Install LastPass-CLI
    if util::is_available chezmoi; then
        ansi --yellow "LastPass-CLI is installed. Skipping"
    else
        ansi --green "LastPass-CLI not installed. Installing..."
        brew install lastpass-cli
    fi
elif [[ "$(util::host_os)" == "linux"* ]]; then
    ansi --yellow "Warning Linux support is untested."
     if util::is_available chezmoi; then
        ansi --yellow "Chezmoi is installed. Skipping"
    else
        ansi --green "Chezmoi not installed. Installing..."

        # Set the bin directory as Chezmoi uses this as the install directory
        export BINDIR="$HOME/bin"
        sh -c "$(wget -qO- https://chezmoi.io/get)" || sh -c "$(curl -fsLS https://chezmoi.io/get)"
    fi
fi
