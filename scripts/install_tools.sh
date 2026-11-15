#!/usr/bin/env bash

# enable unofficial bash strict mode
set -euo pipefail
IFS=$'\n\t'

SRC_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd -P)
SCRIPTS_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=/dev/null
source "${SCRIPTS_ROOT}/lib/init.sh"

# Make sure common user bin directories are on the path
export PATH="$HOME/bin:$SRC_ROOT/bin:/opt/homebrew/bin:$PATH"

host_os="$(util::host_os)"
log::info "HOST_OS=${host_os}"
case "${host_os}" in
    darwin|linux) ;;
    *) log::error_exit "Tool installation is not supported on ${host_os}" ;;
esac

util::setup_brew
if util::is_available brew; then
    ansi --yellow "Homebrew is installed. Skipping"
else
    ansi --green "Homebrew not installed. Installing..."
    util::install_homebrew "$(util::homebrew_prefix)"
fi

if [[ "${host_os}" == darwin ]]; then
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
elif [[ "${host_os}" == linux ]]; then
    # Ensure a C/C++ toolchain. Many Homebrew taps ship no Linux bottles, so brew
    # builds those formulae from source and requires a compiler (otherwise it
    # fails with "Install Clang or run `brew install gcc`").
    if ! util::is_available cc && ! util::is_available gcc; then
        case "$(util::linux_distro)" in
            ubuntu)
                ansi --green "Installing build-essential (compiler for Homebrew source builds)"
                util::run_privileged apt-get update -y
                util::run_privileged apt-get install -y build-essential procps file
                ;;
            arch)
                ansi --green "Installing base-devel (compiler for Homebrew source builds)"
                util::run_privileged pacman -S --needed --noconfirm base-devel
                ;;
            *)
                ansi --yellow "Unknown Linux distro; install a C compiler (gcc) if Homebrew source builds fail"
                ;;
        esac
    fi

    if util::is_available chezmoi; then
        ansi --yellow "Chezmoi is installed. Skipping"
    else
        ansi --green "Chezmoi not installed. Installing..."

        # Set the bin directory as Chezmoi uses this as the install directory
        installer="$(curl -fsLS https://get.chezmoi.io)" \
            || log::error_exit "Could not download the Chezmoi installer"
        [[ -n "${installer}" ]] || log::error_exit "The downloaded Chezmoi installer is empty"
        mkdir -p "$HOME/bin"
        sh -c "${installer}" -- -b "$HOME/bin"
        util::is_available chezmoi || log::error_exit "The Chezmoi installer completed but chezmoi could not be found"
    fi

    # Install age (required to decrypt the passphrase-protected secrets before apply)
    if util::is_available age; then
        ansi --yellow "age is installed. Skipping"
    else
        ansi --green "age not installed. Installing..."
        brew install age
    fi
fi
