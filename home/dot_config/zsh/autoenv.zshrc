export AUTOENV_FILE_ENTER=${AUTOENV_FILE_ENTER:=.autoenv.zsh}
export AUTOENV_FILE_LEAVE=${AUTOENV_FILE_LEAVE:=.autoenv.zsh}
export AUTOENV_DEBUG=${AUTOENV_DEBUG:=0}

export AUTOENV_AUTH_FILE=$HOME/.config/autoenv_auth

source $ZSH_CUSTOM/plugins/zsh-autoenv/autoenv.zsh