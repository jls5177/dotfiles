# Enable pipx completions
if command -v pipx &>/dev/null; then
  _PIPX_LIBEXEC="$(dirname "$(readlink -f "$(which pipx)")")/../libexec/bin"
  if [[ -x "$_PIPX_LIBEXEC/register-python-argcomplete" ]]; then
    eval "$("$_PIPX_LIBEXEC/register-python-argcomplete" pipx)"
  else
    eval "$(register-python-argcomplete pipx)"
  fi
  unset _PIPX_LIBEXEC
fi

#eval "$(_PYMCTP_COMPLETE=zsh_source pymctp)"
