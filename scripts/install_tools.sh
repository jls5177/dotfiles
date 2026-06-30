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
        NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        brew analytics off
    fi

    # Install Chezmoi
    if util::is_available chezmoi; then
        ansi --yellow "Chezmoi is installed. Skipping"
    else
        ansi --green "Chezmoi not installed. Installing..."
        brew install chezmoi
    fi

    # Install age (required to decrypt the passphrase-protected secrets before apply)
    if util::is_available age; then
        ansi --yellow "age is installed. Skipping"
    else
        ansi --green "age not installed. Installing..."
        brew install age
    fi
elif [[ "$(util::host_os)" == "linux"* ]]; then
    ansi --yellow "Warning Linux support is untested."
    # install homebrew
    if util::is_available /home/linuxbrew/.linuxbrew/bin/brew; then
        ansi --yellow "Homebrew is installed. Skipping"
    else
        ansi --green "Homebrew not installed. Installing..."
        NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        /home/linuxbrew/.linuxbrew/bin/brew analytics off
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi

     if util::is_available chezmoi; then
        ansi --yellow "Chezmoi is installed. Skipping"
    else
        ansi --green "Chezmoi not installed. Installing..."

        # Set the bin directory as Chezmoi uses this as the install directory
        export BINDIR="$HOME/bin"
        sh -c "$(wget -qO- https://chezmoi.io/get)" || sh -c "$(curl -fsLS https://chezmoi.io/get)"
    fi

    # Install age (required to decrypt the passphrase-protected secrets before apply)
    if util::is_available age; then
        ansi --yellow "age is installed. Skipping"
    else
        ansi --green "age not installed. Installing..."
        /home/linuxbrew/.linuxbrew/bin/brew install age
    fi
fi
