# Personal dotfiles

This repository hosts my personal set of [dotfiles](https://dotfiles.github.io/). I've published these files to multiple git servers which are more than likely outdated. For the latest version of my dotfiles please use my primary repo: <https://github.com/jls5177/dotfiles>

**Note:** This repo is heavily inspired by Ben Mezger's dotfile repo: <https://github.com/benmezger/dotfiles>

## Installation

The following environment variables can be set to configure Chezmoi behavior:

* `ASK`: Set to `1` if you want to enable chezmoi to prompt you for all values
* `DOTFILES_MINIMAL`: Set to `1` if you want to install the minimal version that installs the basic configurations (see below)
* `SECRETS`: Set to `1` to enable my personal secrets (uses my personal secret vaults to initialize sensitive files, this will fail for everyone else if enabled)

For example, you can enable `ASK` by running `ASK=1 chezmoi apply` or enable a minimal version of the dotfiles with `DOTFILES_MINIMAL=1 chezmoi apply`

### Minimal version

The minimal version installs only the essentials needed for a functional terminal interface:

* zsh
* git
* kitty
* user-dirs

```shell
DOTFILES_MINIMAL=1 chezmoi init https://github.com/jls5177/dotfiles.git -S ~/dotfiles
```

### Full version

> **Note:** This should never be ran by anyone else as you will not have access to my personal secrets vault.

#### Requirements

1. Chezmoi installed
2. lastpass-cli installed ([see here](https://www.chezmoi.io/user-guide/password-managers/lastpass/))
3. Logged into lastpass-cli

#### Initialize Full Config Command

```shell
SECRETS=1 chezmoi init https://github.com/jls5177/dotfiles.git -S ~/dotfiles
```
