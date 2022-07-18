# Chezmoi Cheatsheet 

This document contains various steps I took when creating this repo.

## Adding SSH key into LastPass
```shell
printf "Private Key: %s\nPublic Key: %s" "$(cat ~/.ssh/id_rsa)" "$(cat ~/.ssh/id_rsa.pub)" | lpass add --sync=now --non-interactive --note-type=ssh-key "SSH-Amzn3"
```
