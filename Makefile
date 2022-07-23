LOGFILE=/tmp/dotfiles.log

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

## Allows the caller to move the destination folder (mostly for testing)
# export DST_DIR?=$(HOME)/test_home

## Setup directories based on target being ran (e.g. secrets are deployed as separate
## deployment to prevent constantly needing to input secrets vault credentials)
ifeq (secrets,$(findstring secrets, $(MAKECMDGOALS)))
export SECRETS?=1
export CFG_FILE?=$(HOME)/.config/chezmoi/jls5177-secrets/chezmoi.yaml
else
export CFG_FILE?=$(HOME)/.config/chezmoi/jls5177-default/chezmoi.yaml
endif

export DRYRUN?=false

.PHONY: install-tools
install-tools:
	@$(LOG_STATUS) "Installing required tools.."
	@bash ./scripts/install_tools.sh | tee -a $(LOGFILE) || exit 1

.PHONY: start-deps
start-deps:
	@$(LOG_STATUS) "Ensuring dependencies.."

.PHONY: ensure-deps
ensure-deps: | start-deps install-tools

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
	@$(SCRIPTS_DIR)/chez.sh status

.PHONY: verify
verify: | ensure-deps $(BOLTDB_FILE)
	@$(LOG_STATUS) "verifying Chezmoi state"
	@$(SCRIPTS_DIR)/chez.sh verify

.PHONY: secrets
secrets:
	@$(LOG_STATUS) "Using Secrets config"

.PHONY: post-chezmoi
post-chezmoi:
	@$(LOG_STATUS) "Starting post-apply actions"
	@$(LOG_STATUS) "Post-apply setup complete"
