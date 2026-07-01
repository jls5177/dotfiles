# Personal dotfiles

This repository hosts my personal set of [dotfiles](https://dotfiles.github.io/). I've published these files to multiple git servers which are more than likely outdated. For the latest version of my dotfiles please use my primary repo: <https://github.com/jls5177/dotfiles>

**Note:** This repo is heavily inspired by Ben Mezger's dotfile repo: <https://github.com/benmezger/dotfiles>

## Architecture

This package deploys a single Chezmoi state from the `home/` directory
(`.chezmoiroot = home`). Secrets (SSH keys, rclone credentials) live **in the
repo**, encrypted with [age](https://age-encryption.org). Encryption uses a
passphrase-protected age identity that is committed to the repo at
`home/key.txt.age`: the public recipient (safe to share) is stored in the
Chezmoi config, while the private identity can only be unlocked with a
passphrase you enter at apply time. This keeps everything in one repo with no
external secret vault, while never exposing plaintext secrets.

> Earlier versions used a second "secrets" Chezmoi state backed by LastPass.
> That has been removed in favour of in-repo age encryption.

Everything is driven through a Makefile to ensure a consistent environment when
running Chezmoi.

## Installation

### Quick start (fresh machine)

On a vanilla **macOS**, **Ubuntu**, or **Arch** system none of `git`, `make`,
`age`, or `chezmoi` exist yet. The `bootstrap.sh` script installs those prereqs
with the native package manager, clones this repo, and runs `make` — one command,
no manual setup:

```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/jls5177/dotfiles/chezmoi/bootstrap.sh)"
```

> Use the command-substitution form above (not `curl … | sh`) so your terminal
> stays attached — chezmoi's prompts and the age passphrase need a TTY.

Bootstrap honours a few environment variables: `ASK=1` (prompt for name/email),
`DOTFILES_MINIMAL=1` (skip the Homebrew bundle), `DOTFILES_DIR` (checkout path),
and `DOTFILES_REF` (branch/tag). Example: `ASK=1 sh -c "$(curl -fsSL …bootstrap.sh)"`.

### Prerequisites

* [`age`](https://age-encryption.org) is required to unlock the encrypted
  identity (`home/key.txt.age`). `bootstrap.sh` installs it; otherwise install it
  from your package manager (`brew install age`, `apt install age`, `pacman -S age`).
* You will be prompted for the age passphrase whenever Chezmoi needs to decrypt
  a managed secret (`apply`, `status-secrets`). Only the repo owner knows this
  passphrase; without it the encrypted files cannot be read.

The following environment variables can be set to configure Chezmoi behavior:

* `ASK`: Set to `1` if you want to enable chezmoi to prompt you for all values during initialization. Which you should always enable unless you are deploying into an environment without a TTY terminal.

For example, you can enable `ASK` by running `ASK=1 make reinit`.

### Manual install (repo already cloned)

```shell
cd ~/jls5177-dotfiles && ASK=1 make
```

### Rerunning Initialization

Run the following command to re-run the initialization process. Which basically deleted the configuration and recreates it. Reprompting you for your details.

```shell
cd ~/jls5177-dotfiles && git pull -r && ASK=1 make reinit
```

### Make Goals

The included makefile is a thin wrapper around Chezmoi commands. Here is a brief breakdown of each supported goal:

* `init` -> `chezmoi init`
* `apply` -> `chezmoi apply` (unlocks the age key once, single passphrase prompt)
* `status` -> `chezmoi status` (excludes encrypted secrets, so it never prompts)
* `status-secrets` -> like `status` but includes encrypted secrets (one prompt)
* `verify` -> `chezmoi verify`
* `help` -> list the available goals and variables

Run `make help` for the full list including supported variables.

### Helper Scripts

* `scripts/chez.sh`: Simple wrapper around Chezmoi that allows you to run any Chezmoi command (useful for debugging/advanced usecases)

### Managing secrets

Secrets are encrypted with age against the recipient stored in the Chezmoi
config. Adding or updating a secret only needs the public recipient (no
passphrase); reading or applying it requires the passphrase.

To avoid a passphrase prompt for every encrypted file, the wrapper decrypts the
passphrase-protected identity **once** into an ephemeral plaintext key and points
Chezmoi at it for that run (the temp key is shredded on exit). So `apply` and
`status-secrets` prompt a single time, while `status` skips secrets entirely and
never prompts.

```shell
# add/update an encrypted secret
./scripts/chez.sh add --encrypt ~/.ssh/id_rsa_msft

# inspect the decrypted contents (prompts for the passphrase once)
./scripts/chez.sh cat ~/.ssh/id_rsa_msft
```

The passphrase-protected identity lives at `home/key.txt.age`. To rotate it,
generate a new key, re-encrypt every secret against the new recipient, update
`home/.chezmoi.yaml.tmpl`, and re-commit `home/key.txt.age`.
