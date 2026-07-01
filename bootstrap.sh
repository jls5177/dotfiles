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
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/jls5177/dotfiles/master/bootstrap.sh)"
#
# Optional environment variables:
#   DOTFILES_REPO   git URL to clone       (default: https://github.com/jls5177/dotfiles.git)
#   DOTFILES_DIR    checkout location      (default: $HOME/jls5177-dotfiles)
#   DOTFILES_REF    branch/tag to checkout (default: repo default)
#   ASK=1           prompt for name/email during chezmoi init

set -eu

REPO_URL="${DOTFILES_REPO:-https://github.com/jls5177/dotfiles.git}"
DEST="${DOTFILES_DIR:-$HOME/jls5177-dotfiles}"
REF="${DOTFILES_REF:-}"

# Make user-local bin dirs visible so freshly-installed tools are found.
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

info() { printf '\033[0;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[0;33mWARN:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[0;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

# Prefix privileged commands with sudo unless already root.
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if have sudo; then
    SUDO="sudo"
  else
    warn "not root and sudo not found; package installs may fail"
  fi
fi

detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)
      os_id=""
      if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        os_id="${ID:-} ${ID_LIKE:-}"
      fi
      case "$os_id" in
        *arch*) echo "arch" ;;
        *debian*|*ubuntu*) echo "ubuntu" ;;
        *) echo "linux-unknown" ;;
      esac
      ;;
    *) echo "unsupported" ;;
  esac
}

install_chezmoi_get() {
  # chezmoi is not in apt; use the official installer. Install into ~/bin to match
  # where install_tools.sh looks (the Makefile wrappers put ~/bin on PATH).
  info "Installing chezmoi via get.chezmoi.io"
  mkdir -p "$HOME/bin"
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/bin"
}

prereqs_macos() {
  # Homebrew installs the Command Line Tools (git + make) as part of setup.
  if ! have brew; then
    info "Installing Homebrew (also provides git + make)"
    NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  # Ensure brew is on PATH for this session (Apple Silicon or Intel).
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  have age && have chezmoi || { info "Installing age + chezmoi via Homebrew"; brew install age chezmoi; }
}

prereqs_ubuntu() {
  info "Installing git, make, age via apt"
  $SUDO apt-get update -y
  $SUDO apt-get install -y git make age curl ca-certificates
  have chezmoi || install_chezmoi_get
}

prereqs_arch() {
  info "Installing git, make, age, chezmoi via pacman"
  $SUDO pacman -Sy --needed --noconfirm git make age chezmoi
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
  info "Done. Re-run with 'ASK=1 make reinit' to change your name/email."
}

main "$@"
