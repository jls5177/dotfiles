# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
ZSH_THEME="agnoster"

# Would you like to use another custom folder than $ZSH/custom?
ZSH_CUSTOM=$HOME/.config/zsh

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
plugins=(
  osx
  brew
  direnv
  dirhistory
  extract
  git
  git-extras
  history
  last-working-dir
  vscode
  wd
)

#fpath=(~/.zfunc $fpath)

source $ZSH/oh-my-zsh.sh

# User configuration

# Preferred editor for local and remote sessions
export EDITOR='vim'

# Be nice or mean!
alias please="sudo"
alias fucking="sudo"

# Print a programming excuse on each new shell
alias shuf=gshuf
$HOME/code/github/programmingexcuses.sh/programmingexcuses | cowsay

# add user bin to the path
export PATH=$HOME/bin:$PATH

export PATH=$HOME/.toolbox/bin:$HOME/scripts:$PATH
