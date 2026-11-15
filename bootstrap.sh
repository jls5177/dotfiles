#!/bin/sh
# Bootstrap jls5177/dotfiles on a vanilla system (macOS, Ubuntu, Arch).
#
# Installs the minimal prerequisites (git, make, age, chezmoi) using the native
# package manager, clones the repo, and hands off to `make`. This breaks the
# chicken-and-egg problem where none of make/age/chezmoi exist yet.
#
# Run it so that the terminal stays attached (needed for the config prompts and
# the age passphrase) -- use command substitution, NOT a pipe:
#
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/jls5177/dotfiles/chezmoi/bootstrap.sh)"
#
# Optional environment variables:
#   DOTFILES_REPO   git URL to clone       (default: https://github.com/jls5177/dotfiles.git)
#   DOTFILES_DIR    checkout location      (default: $HOME/jls5177-dotfiles)
#   DOTFILES_REF    branch/tag to checkout (default: repo default)
#   ASK=1           prompt for name/email during chezmoi init
#   DOTFILES_SHELL  zsh (default) or fish; saved during chezmoi init

set -eu

REPO_URL="${DOTFILES_REPO:-https://github.com/jls5177/dotfiles.git}"
DEST="${DOTFILES_DIR:-$HOME/jls5177-dotfiles}"
REF="${DOTFILES_REF:-}"

case "${DOTFILES_SHELL:-zsh}" in
  zsh|fish) ;;
  *) printf '%s\n' "DOTFILES_SHELL must be zsh or fish" >&2; exit 1 ;;
esac

# Make user-local bin dirs visible so freshly-installed tools are found.
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

info() { printf '\033[0;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[0;33mWARN:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[0;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

ensure_sudo() {
  [ "$(id -u)" -ne 0 ] || return 0
  have sudo || die "Administrator access is required, but sudo is not installed. Ask your administrator to provision the tools."
  if sudo -n -v 2>/dev/null; then
    return 0
  fi
  if [ -t 0 ] && [ -z "${NONINTERACTIVE:-}" ] && [ -z "${CI:-}" ]; then
    info "Administrator access is required; authenticating with sudo."
    sudo -v || die "Sudo authentication failed. Verify your administrator access and retry."
  else
    die "Sudo authentication is required. Run 'sudo -v' in a terminal and retry in that terminal, or ask your administrator to provision the tools for unattended installation."
  fi
}

run_privileged() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    ensure_sudo
    sudo -n "$@"
  fi
}

setup_brew() {
  if ! have brew; then
    for brew_candidate in /opt/homebrew/bin/brew /usr/local/bin/brew \
      /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
      if [ -x "$brew_candidate" ]; then
        PATH="$(dirname "$brew_candidate"):$PATH"
        export PATH
        break
      fi
    done
  fi
  if have brew; then
    brew_environment="$(brew shellenv sh)" || die "Could not load the Homebrew environment."
    eval "$brew_environment"
  fi
}

detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)
      os_id=""
      os_release_file="${1:-/etc/os-release}"
      if [ -r "$os_release_file" ]; then
        # shellcheck source=/dev/null
        . "$os_release_file"
        os_id="${ID:-} ${ID_LIKE:-}"
      fi
      for os_family in $os_id; do
        case "$os_family" in
          arch) echo "arch"; return ;;
          debian|ubuntu) echo "ubuntu"; return ;;
        esac
      done
      echo "linux-unknown"
      ;;
    *) echo "unsupported" ;;
  esac
}

install_chezmoi_get() {
  # chezmoi is not in apt; use the official installer. Install into ~/bin to match
  # where install_tools.sh looks (the Makefile wrappers put ~/bin on PATH).
  info "Installing chezmoi via get.chezmoi.io"
  mkdir -p "$HOME/bin"
  chezmoi_installer="$(curl -fsLS https://get.chezmoi.io)" || die "Could not download the Chezmoi installer."
  [ -n "$chezmoi_installer" ] || die "The downloaded Chezmoi installer is empty."
  sh -c "$chezmoi_installer" -- -b "$HOME/bin"
}

prereqs_macos() {
  # Homebrew installs the Command Line Tools (git + make) as part of setup.
  setup_brew
  if ! have brew; then
    info "Installing Homebrew (also provides git + make)"
    brew_parent=/opt/homebrew
    [ "$(uname -m)" = arm64 ] || brew_parent=/usr/local
    while [ ! -e "$brew_parent" ]; do
      brew_parent="$(dirname "$brew_parent")"
    done
    if [ ! -w "$brew_parent" ] || [ ! -x "$brew_parent" ]; then
      ensure_sudo
    fi
    brew_installer="$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
      || die "Could not download the Homebrew installer."
    [ -n "$brew_installer" ] || die "The downloaded Homebrew installer is empty."
    NONINTERACTIVE=1 /bin/bash -c "$brew_installer"
    setup_brew
    have brew || die "The Homebrew installer completed but brew could not be found."
  fi
  if ! have age || ! have chezmoi; then
    info "Installing age + chezmoi via Homebrew"
    brew install age chezmoi
  fi
}

prereqs_ubuntu() {
  info "Installing git, make, age via apt"
  run_privileged apt-get update -y
  run_privileged apt-get install -y git make age curl ca-certificates
  have chezmoi || install_chezmoi_get
}

prereqs_arch() {
  info "Installing git, make, age, chezmoi via pacman"
  run_privileged pacman -Sy --needed --noconfirm git make age chezmoi
}

main() {
  os="$(detect_os)"
  info "Detected OS: $os"
  case "$os" in
    macos)  prereqs_macos ;;
    ubuntu) prereqs_ubuntu ;;
    arch)   prereqs_arch ;;
    *) die "Unsupported OS. This bootstrap supports macOS, Ubuntu, and Arch." ;;
  esac

  have git  || die "git is required but was not installed"
  have make || die "make is required but was not installed"

  if [ -d "$DEST/.git" ]; then
    info "Repo already present at $DEST"
  else
    info "Cloning $REPO_URL -> $DEST"
    git clone "$REPO_URL" "$DEST"
  fi

  if [ -n "$REF" ]; then
    info "Checking out $REF"
    git -C "$DEST" checkout "$REF"
  fi

  info "Running make in $DEST"
  cd "$DEST"
  make
  info "Done. Use 'DOTFILES_SHELL=fish make reinit' then 'make apply' to switch shell configuration."
}

main "$@"
