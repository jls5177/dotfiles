LOGFILE=/tmp/dotfiles.log

ifneq ($(strip $(DOTFILES_SHELL)),)
ifneq ($(DOTFILES_SHELL),zsh)
ifneq ($(DOTFILES_SHELL),fish)
$(error DOTFILES_SHELL must be zsh or fish)
endif
endif
endif

# Setup directory helper variables
export SOURCE_DIR  := $(CURDIR)
export SCRIPTS_DIR := $(CURDIR)/scripts

# Setup logging helpers
export LOGGER      := $(SCRIPTS_DIR)/make_rules/log_status.sh
LOG_STATUS = "${LOGGER}" status
LOG_INFO = "${LOGGER}" info
LOG_DEBUG = "${LOGGER}" debug

# Set default goal to "apply"
default: apply

.PHONY: help
help:
	@echo "Personal dotfiles (chezmoi). Usage: make [VAR=value] <goal>"
	@echo ""
	@echo "Goals:"
	@echo "  apply        Apply the chezmoi state to \$$HOME (default goal)"
	@echo "  status       Show pending changes (secrets & externals excluded, no passphrase)"
	@echo "  status-secrets Show pending changes including encrypted secrets (one passphrase)"
	@echo "  verify       Verify the destination matches the chezmoi state"
	@echo "  init         Initialize the chezmoi state/config"
	@echo "  reinit       Re-run initialization, recreating the config"
	@echo "  install-tools  Install required tools (homebrew, chezmoi, age)"
	@echo "  test         Validate isolated shell deployment and helper behavior"
	@echo "  help         Show this help"
	@echo ""
	@echo "Variables:"
	@echo "  ASK=1        Prompt for all config values during (re)init"
	@echo "  DOTFILES_SHELL=zsh|fish  Select shell during (re)init (default: zsh)"
	@echo "  DOTFILES_MINIMAL=1  Skip optional Homebrew bundles during initialization"
	@echo "  DRYRUN=true  Print chezmoi commands instead of running them"
	@echo "  VERBOSE=1|2  Enable chezmoi --debug (1) and --verbose (2) output"
	@echo "  CFG_FILE=... Override the chezmoi config path"
	@echo ""
	@echo "Notes:"
	@echo "  Secrets are age-encrypted. 'status' skips them so it never prompts;"
	@echo "  'apply'/'status-secrets' unlock the key once (a single passphrase prompt)."
	@echo "  The 'age' binary is required (installed by install-tools)."

## Allows the caller to move the destination folder (mostly for testing)
# export DST_DIR?=$(HOME)/test_home

export CFG_FILE?=$(HOME)/.config/chezmoi/jls5177-default/chezmoi.yaml

export DRYRUN?=false

.PHONY: install-tools
install-tools:
	@$(LOG_STATUS) "Installing required tools.."
	@bash -o pipefail -c 'bash ./scripts/install_tools.sh 2>&1 | tee -a "$$1"' -- "$(LOGFILE)"

.PHONY: start-deps
start-deps:
	@$(LOG_STATUS) "Ensuring dependencies.."

.PHONY: ensure-deps
ensure-deps: | start-deps install-tools

.PHONY: test
test:
	@python3 tests/test_shells.py

.PHONY: init
init: | ensure-deps
	@$(LOG_STATUS) "initializing Chezmoi state"
	@$(SCRIPTS_DIR)/chez.sh init

.PHONY: reinit
reinit: export REINIT=true
reinit: | ensure-deps
	@$(LOG_STATUS) "reinitializing Chezmoi state"
	@$(SCRIPTS_DIR)/chez.sh init

# The BOLTDB file should exist if the repo was initialized
# This target will skip initialization of the file is present
BOLTDB_FILE := $(dir $(CFG_FILE))chezmoistate.boltdb
$(BOLTDB_FILE):
	@$(LOG_STATUS) "Initializing chezmoi.."
	@$(SCRIPTS_DIR)/chez.sh init

.PHONY: apply
apply: | ensure-deps $(BOLTDB_FILE)
	@$(LOG_STATUS) "Applying chezmoi.."
	@$(SCRIPTS_DIR)/chez.sh apply

.PHONY: status
status: | ensure-deps $(BOLTDB_FILE)
	@$(LOG_STATUS) "fetching Chezmoi status"
	@$(SCRIPTS_DIR)/chez.sh status --exclude encrypted,externals

.PHONY: status-secrets
status-secrets: export CHEZ_DECRYPT=1
status-secrets: | ensure-deps $(BOLTDB_FILE)
	@$(LOG_STATUS) "fetching Chezmoi status (including encrypted secrets)"
	@$(SCRIPTS_DIR)/chez.sh status --exclude externals

.PHONY: verify
verify: | ensure-deps $(BOLTDB_FILE)
	@$(LOG_STATUS) "verifying Chezmoi state"
	@$(SCRIPTS_DIR)/chez.sh verify --exclude encrypted,externals

.PHONY: post-chezmoi
post-chezmoi:
	@$(LOG_STATUS) "Starting post-apply actions"
	@$(LOG_STATUS) "Post-apply setup complete"
