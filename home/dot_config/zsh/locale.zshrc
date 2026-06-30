# Ensure a valid POSIX locale.
#
# Some terminals (notably kitty on macOS) export the system locale in BCP-47/ICU
# form, e.g. LC_ALL=en_US-u-hc-h12-u-ca-gregory-u-nu-latn. That is NOT a valid
# POSIX locale, so perl/bash/cowsay/etc. emit "setlocale: Invalid argument"
# warnings and silently fall back to the C locale.
#
# This shard is a portable fallback (kitty.conf already forces a good LC_ALL):
# if the effective locale isn't an installed POSIX locale, drop the bad value
# and fall back to a sane UTF-8 locale.

() {
  local effective="${LC_ALL:-${LANG}}"
  if [[ -n "$effective" ]] && ! locale -a 2>/dev/null | grep -qxi "$effective"; then
    unset LC_ALL
    if locale -a 2>/dev/null | grep -qxi 'en_US.UTF-8'; then
      export LANG=en_US.UTF-8
    else
      export LANG=C.UTF-8
    fi
  fi
}
