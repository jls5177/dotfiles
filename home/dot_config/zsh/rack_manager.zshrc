# Keep Bash-only redirections and logging in an explicit interpreter.
ssh-rm() { "$HOME/scripts/dotfiles-helper" rm ssh-rm "$@"; }
ssh-bmc() { "$HOME/scripts/dotfiles-helper" rm ssh-bmc "$@"; }
ssh-bmc-su() { "$HOME/scripts/dotfiles-helper" rm ssh-bmc-su "$@"; }
scp-bmc() { "$HOME/scripts/dotfiles-helper" rm scp-bmc "$@"; }
scp-bmc-su() { "$HOME/scripts/dotfiles-helper" rm scp-bmc-su "$@"; }
sftp-rm() { "$HOME/scripts/dotfiles-helper" rm sftp-rm "$@"; }
rmPortForward() { "$HOME/scripts/dotfiles-helper" rm rmPortForward "$@"; }
ip2dec() { "$HOME/scripts/dotfiles-helper" rm ip2dec "$@"; }
clean_control_chars() { "$HOME/scripts/dotfiles-helper" rm clean_control_chars "$@"; }
filter_output() { "$HOME/scripts/dotfiles-helper" rm filter_output "$@"; }
format_line() { "$HOME/scripts/dotfiles-helper" rm format_line "$@"; }
change-rm-password() { "$HOME/scripts/dotfiles-helper" rm change-rm-password "$@"; }
change-bmc-password() { "$HOME/scripts/dotfiles-helper" rm change-bmc-password "$@"; }
change-bmc-password-su() { "$HOME/scripts/dotfiles-helper" rm change-bmc-password-su "$@"; }
ssh-port-tunnelling() { "$HOME/scripts/dotfiles-helper" rm ssh-port-tunnelling "$@"; }
rm_ssh() {
  SSH_ASKPASS_REQUIRE=force SSH_ASKPASS="$HOME/.rm-pass" ssh -oLogLevel=error -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oServerAliveInterval=60 -c aes256-cbc "$@"
}
