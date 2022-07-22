LOGFILE=/tmp/dotfiles.log

# Setup directory helper variables
export SOURCE_DIR  := $(CURDIR)
export SCRIPTS_DIR := $(CURDIR)/scripts

# Setup logging helpers
export LOGGER      := $(SCRIPTS_DIR)/make_rules/log_status.sh
LOG_STATUS = "${LOGGER}" status
LOG_INFO = "${LOGGER}" info
LOG_DEBUG = "${LOGGER}" debug

# Set default goal to "run-default"
default: run-default

## Allows the caller to move the destination folder (mostly for testing)
# export DST_DIR?=$(HOME)/test_home

## Setup directories based on target being ran (e.g. secrets are deployed as separate
## deployment to prevent constantly needing to input secrets vault credentials)
ifeq (,$(findstring $(MAKECMDGOALS), run-secrets secrets-init secrets-status))
$(info NOTE: Using default config)
export SRC_DIR?=$(SOURCE_DIR)
export CFG_FILE?=$(HOME)/.config/chezmoi/default/chezmoi.yaml
else
$(info NOTE: Using secrets config)
export SRC_DIR?=$(SOURCE_DIR)/secrets
export CFG_FILE?=$(HOME)/.config/chezmoi/secrets/chezmoi.yaml
endif

export DRYRUN?=true
export REINIT?=false

.PHONY: install-chezmoi
install-chezmoi:
	@$(LOG_STATUS) "Installing chezmoi.."
	@bash ./scripts/install_chezmoi.sh | tee -a $(LOGFILE) || exit 1

.PHONY: install-homebrew
install-homebrew:
	@$(LOG_STATUS) "Installing homebrew.."
	@bash ./scripts/install_homebrew.sh | tee -a $(LOGFILE) || exit 1

.PHONY: start-deps
start-deps:
	@$(LOG_STATUS) "Ensuring dependencies.."

.PHONY: ensure-deps
ensure-deps: | start-deps install-homebrew install-chezmoi

# This goal allows for reinitializing the configuration
.PHONY: chezmoi-init
ifeq ($(REINIT), true)
chezmoi-init: DATA=false
else
chezmoi-init: DATA=true
endif
chezmoi-init: | ensure-deps
	@$(LOG_STATUS) "initializing Chezmoi state"
	@$(SCRIPTS_DIR)/make_rules/run_chezmoi.sh init

# The BOLTDB file should exist if the repo was initialized
# This target will skip initialization of the file is present
BOLTDB_FILE := $(dir $(CFG_FILE))chezmoistate.boltdb
$(BOLTDB_FILE):
	@$(LOG_STATUS) "Initializing chezmoi.."
	@$(SCRIPTS_DIR)/make_rules/run_chezmoi.sh init

.PHONY: chezmoi-apply
chezmoi-apply: | ensure-deps $(BOLTDB_FILE)
	@$(LOG_STATUS) "Applying chezmoi.."
	@$(SCRIPTS_DIR)/make_rules/run_chezmoi.sh apply

.PHONY: chezmoi-status
chezmoi-status: | ensure-deps $(BOLTDB_FILE)
	@$(LOG_STATUS) "fetching Chezmoi status"
	@$(SCRIPTS_DIR)/make_rules/run_chezmoi.sh status

.PHONY: chezmoi-verify
chezmoi-verify: | ensure-deps $(BOLTDB_FILE)
	@$(LOG_STATUS) "verifying Chezmoi state"
	@$(SCRIPTS_DIR)/make_rules/run_chezmoi.sh verify

.PHONY: run-default run-secrets
run-default run-secrets: chezmoi-apply

.PHONY: init-default init-secrets
init-default init-secrets: chezmoi-init

.PHONY: secrets-status
secrets-status: chezmoi-status

.PHONY: secrets-verify
secrets-verify: chezmoi-verify

.PHONY: post-chezmoi
post-chezmoi:
	@$(LOG_STATUS) "Starting post-install actions"
	@$(LOG_STATUS) "Post-install setup done"
