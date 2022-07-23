#!/usr/bin/env bash
set -euo pipefail

LOGFILE="/tmp/dotfiles.log"

echo "Running '$0' $(date)" | tee -a $LOGFILE
DOTFILES_MINIMAL=1 make
