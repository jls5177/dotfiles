# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
ZSH_THEME="agnoster"

# Would you like to use another custom folder than $ZSH/custom?
ZSH_CUSTOM=$HOME/.config/zsh

# Setup FZF installation directory for OMZ plugin below
export FZF_BASE=/usr/local/opt/fzf

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
plugins=(
  osx
  brew
  direnv
  dirhistory
  extract
  fzf
  git
  git-extras
  history
  last-working-dir
  vscode
  wd
)

#fpath=(~/.zfunc $fpath)
fpath=(~/.zsh/completion $fpath)
autoload -Uz compinit && compinit -i

source $ZSH/oh-my-zsh.sh

# User configuration

# Preferred editor for local and remote sessions
export EDITOR='vim'

# add user bin to the path
export PATH=$HOME/bin:$PATH

export PATH=$HOME/.toolbox/bin:$HOME/scripts:$PATH

# Source individual config shards (with suffix of ".zshrc")
# this allows to break up configuration and apply different settings using YADM
for filename in $HOME/.config/zsh/*.zshrc; do
	source $filename
done

