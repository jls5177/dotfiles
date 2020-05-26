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
fpath=(~/.zsh/completion $fpath)
autoload -Uz compinit && compinit -i

source $ZSH/oh-my-zsh.sh

# User configuration

# Preferred editor for local and remote sessions
export EDITOR='vim'

# Be nice or mean!
alias please="sudo"
alias fucking="sudo"

# Print a programming excuse on each new shell
if [ "$(uname -s)" = "Darwin" ]; then
  alias shuf=gshuf
fi
$HOME/.config/programmingexcuses/programmingexcuses | cowsay

# add user bin to the path
export PATH=$HOME/bin:$PATH

export PATH=$HOME/.toolbox/bin:$HOME/scripts:$PATH

# Kitty terminal config
alias icat="kitty +kitten icat"
alias dcat="kitty +kitten diff"
alias clipcat="kitty +kitten clipboard"

# Add SAMToolkit
alias sam-toolkit="brazil-build-tool-exec sam"

