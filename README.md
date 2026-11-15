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

Set `DOTFILES_SHELL=fish` on that command to select Fish. The default is Zsh.

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

### Selecting Zsh or Fish

The selected shell is saved **per machine** in Chezmoi's `config_state.shell`.
Both implementations stay in this repository; only the selected shell's files
and framework/plugin downloads are managed. Existing configurations without a
shell selection continue to use Zsh.

```shell
# Fresh installation
DOTFILES_SHELL=fish make

# Switch an initialized machine (use zsh to switch back)
DOTFILES_SHELL=fish make reinit
make apply

# Include identity/minimal-mode prompts
DOTFILES_SHELL=fish ASK=1 make reinit
```

`DOTFILES_SHELL` accepts only `zsh` or `fish`. It is an initialization input,
not an apply-time override: reinitialize before changing an existing selection.
`ASK=1` also offers a shell choice. Reinitializing without a new shell choice
preserves the saved shell, including through the Make wrapper's `--data=false`.

Switching does **not** delete inactive-shell files or uninstall packages. It
stops updating those files and downloading their plugins until you switch back.
A fresh Fish installation does not download Oh My Zsh or Zsh plugins, nor
explicitly install Zsh. An OS-provided or previously installed Zsh is left alone.
The existing email/domain and OS exclusions also apply to Fish helpers.

Both shells use `~/.config/starship.toml` for the prompt. Zsh still uses Oh My
Zsh for its plugins, but no longer loads Agnoster. Fish uses its built-in
autosuggestions, highlighting, completion, and history, without a plugin manager.
Starship unifies the prompt, **not** the rest of the shell configuration.
The prompt works with an ordinary font; a Nerd Font improves optional tool icons.

The selected shell and Starship are required dependencies even in minimal mode.
Shells are installed with Homebrew on macOS and apt/pacman on Ubuntu/Arch;
Linux distro families are detected from `ID`/`ID_LIKE`, so Arch derivatives such
as CachyOS use pacman too. Starship uses the existing Homebrew infrastructure.
Minimal mode skips optional Homebrew bundles on **both macOS and Linux**; the
existing native Ubuntu package list is not changed by this option.

Nonminimal macOS and Linux installs run `Brewfile-common`. macOS also uses its
desktop/architecture bundles; only Ubuntu uses `Brewfile-Ubuntu`. Existing
email-based company profiles are retained: the Microsoft CLI profile is usable
on Linux, its Edge cask is macOS-only, and the Amazon package bundle remains
macOS-only.

### Prerequisite installation and administrator access

`make install-tools` discovers Homebrew on PATH or in its standard macOS/Linux
locations, loads its environment, and installs missing prerequisites. Repeated
runs reuse installed tools rather than reinstalling Homebrew.

Creating the default Homebrew prefix or installing native system packages may
require administrator access. The scripts use cached/passwordless sudo when
available, otherwise prompt through sudo if stdin is a terminal. Logging output
through `tee` does not suppress that prompt. Neither the scripts nor this
repository store your sudo password.

Without a terminal, or with `CI`/`NONINTERACTIVE` set to a nonempty value, the
scripts do not prompt: provision the required tools, arrange appropriate
passwordless permissions, or authenticate and retry in the same terminal:

```shell
sudo -v
make install-tools
```

An installer or logging failure stops Make before initialization/apply proceeds.
Installer stdout and stderr are saved in `/tmp/dotfiles.log`.

Optional bundles use Chezmoi `run_onchange`: relevant manifest edits, profile
changes, and minimal-mode changes trigger installation; unchanged applies do
not check for packages removed by hand. The repaired Linux bundle hook reruns
on the next `make apply` because its rendered contents changed; resetting
Chezmoi state is not necessary. To intentionally change saved deployment
options, use `ASK=1 make reinit` followed by `make apply`.

### What carries over to Fish?

| Feature | Fish support / migration |
| --- | --- |
| Git/SSH/rclone, Kitty and desktop configs, encrypted secrets | Unchanged; these are not Zsh programs |
| Executable Bash/POSIX/Expect/Python scripts | Keep their interpreters; invoke them normally rather than sourcing them |
| PATH, editor, locale, Go/Rust, Agency/CDE/depot_tools | Native Fish environment setup; PATH additions are deduplicated and not written as universal variables |
| Autosuggestions, highlighting, completion and history | Built into Fish; `prevd`/`nextd` replace directory-history navigation |
| Prompt | Shared Starship configuration, native initialization in each shell |
| direnv, fnm, pyenv, conda, fzf, pipx and VS Code hooks | Native Fish hooks when the tools are installed; fzf 0.48+ uses `fzf --fish`, with older key-binding-file fallback |
| Zsh autoenv | Fish uses direnv instead; migrate `.autoenv.zsh` to Bash-compatible `.envrc`, review it, then run `direnv allow`. Enter/leave logic is not mechanically interchangeable |
| NVM | Fish uses fnm instead. Install the required Node versions with fnm and preserve project `.nvmrc`/`.node-version` files; `nvm.sh` is not sourced |
| Git aliases, forgit, Kitty shortcuts, extract, wd | Fish aliases/functions; forgit aliases such as `ga`/`gd` retain precedence over plain Git aliases |
| Last working directory | Restored when an interactive Fish starts in `$HOME`; state is stored under `$XDG_STATE_HOME/dotfiles` (default `~/.local/state/dotfiles`) |
| Microsoft BitBake/RM/ADO and Amazon Brazil/SAM/Odin/Midway helpers | Retain email/OS filtering; shell-changing behavior uses Fish functions, command-only forgit/RM/ADO logic uses explicit Bash runners |

Fish cannot source Zsh plugins or Bash startup scripts. Optional Fish hooks
run only for interactive sessions. Export tool overrides for command-only
helpers (for example `set -gx FORGIT_COPY_CMD wl-copy` or `set -gx LOG_FILE ...`)
so their Bash subprocesses inherit them. The repository's common Git aliases
and custom helper commands are supplied; the entire OMZ alias namespace is not
replicated. Git-extras and Homebrew commands remain ordinary executables.

The legacy `ado-generate-pat` and `ado-push-pat` commands have been removed.
`ado-push`, `ado-pull`, and `ado-fetch` remain and use Git's configured credential
helper; this change adds no authentication or token-generation workflow.
Credentials must remain outside the repository.

Some company helpers require tools not included here. In particular, CDD's
`dev-tool` is missing from this repository: set `DEV_TOOL_BIN` to an installed
executable before using `cdd_*`. Midway needs the existing Amazon Alfred workflow.
Fish's `git-package` is a function so its final `cd` affects the current shell.
Fish Perl paths use `$HOME/perl5` instead of the legacy hardcoded macOS home.
`bbdbgrefresh` retains the existing build layout; it does not discover newer
Yocto package layouts automatically.

### Changing the login shell

Deployment **does not** change your account's login shell or `/etc/shells`.
After applying, the post-install message prints the installed shell path and
manual switching command when needed. Check that the resolved path appears in
`/etc/shells`; ask your administrator to register it if necessary, then run:

```shell
chsh -s /absolute/path/to/fish
```

Start a new login session afterward. Kitty currently follows your account's
default shell, so deploying Fish files alone does not make Kitty start Fish.
You can run `fish` explicitly to try it without changing your login shell.

### Validation

With `chezmoi`, `fish`, `zsh`, and Python 3 installed, run `make test` (or
`CHEZMOI=/path/to/chezmoi make test`). The tests use temporary homes/configuration
and fake company commands: they do not install packages, download externals,
decrypt secrets, or change account settings. The matrix renders macOS/Ubuntu/Arch
and CachyOS targets, and covers fake sudo/installer failures and terminal handling.
ShellCheck and manifest-only Ruby checks run when their interpreters are available
(override with `SHELLCHECK=...` and `RUBY=...`). Actual interactive validation on
each OS remains necessary before claiming live platform/service compatibility.

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
