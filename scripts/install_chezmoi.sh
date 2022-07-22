#!/usr/bin/env bash

# enable unofficial bash strict mode
set -euo pipefail
IFS=$'\n\t'

SCRIPTS_ROOT=$(cd "$(dirname "${BASH_SOURCE}")" && pwd -P)
source "${SCRIPTS_ROOT}/lib/init.sh"

if ! [ -x "$(command -v chezmoi)" ]; then
	if [[ "$(util::host_os)" == "darwin"* ]]; then
		util::is_available brew || curl -sfL https://git.io/chezmoi | sh
		util::is_available brew && brew install chezmoi
	elif [[ "$(util::host_os)" == "linux"* ]]; then
		ansi --yellow "Warning Linux support is untested."
		# log::error "TODO: this only supports OSes with pacman installed. This may fail..."
		# util::is_available chezmoi || sudo -v || sudo pacman -S chezmoi --noconfirm
		if util::is_available chezmoi; then
			ansi --yellow "Chezmoi is installed. Skipping"
    else
			ansi --green "Chezmoi not installed. Installing..."
			sh -c "$(wget -qO- https://chezmoi.io/get)" || sh -c "$(curl -fsLS https://chezmoi.io/get)"
    fi
	fi
else
	ansi --yellow "Chezmoi is installed, skipping."
fi
