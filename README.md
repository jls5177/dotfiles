# Personal dotfiles

This repository hosts my personal set of [dotfiles](https://dotfiles.github.io/). I've published these files to multiple git servers which are more than likely outdated. For the latest version of my dotfiles please use my primary repo: <https://github.com/jls5177/dotfiles>

**Note:** This repo is heavily inspired by Ben Mezger's dotfile repo: <https://github.com/benmezger/dotfiles>

## Architecture

This package uses custom Chezmoi config directories to deploy multiple Chezmoi states. This allows for isolating my Secrets so
they are not included with the normal Chezmoi state. Which causes constant password prompts and slows down the normal Chezmoi
workflow. In addition, this separation allows for anyone to quickly deploy my dotfiles without much hassle.

Everything is driven through a Makefile to ensure a consistent environment when running Chezmoi. This allows you to have your own dotfiles
deployed with Chezmoi.

## Installation

The following environment variables can be set to configure Chezmoi behavior:

* `ASK`: Set to `1` if you want to enable chezmoi to prompt you for all values. Which you should always enable unless you are deploying into an environment without a TTY terminal.

For example, you can enable `ASK` by running `ASK=1 make`.

### Default version

The minimal version installs only the essentials needed for a functional terminal interface:

* zsh
* git
* kitty
* user-dirs

```shell
mkdir -p ~/jls5177-dotfiles && cd ~/jls5177-dotfiles && git clone https://github.com/jls5177/dotfiles.git . && ASK=1 make
```

### Secrets version

> **Note:** This should never be ran by anyone else as you will not have access to my personal secrets vault.

```shell
cd ~/jls5177-dotfiles && make run-secrets
```
