# Chezmoi Cheatsheet 

This document contains various steps I took when creating this repo.

## Managing secrets with age

Secrets are encrypted in-repo with age, unlocked by a passphrase-protected
identity committed at `home/key.txt.age`.

```shell
# Add/update an encrypted secret (uses the public recipient, no passphrase)
./scripts/chez.sh add --encrypt ~/.ssh/id_rsa_msft

# View the decrypted contents (prompts for the passphrase)
./scripts/chez.sh cat ~/.ssh/id_rsa_msft
```

### Generating / rotating the age key

```shell
# 1) generate a new identity (keep the printed public recipient)
age-keygen -o /tmp/key.txt

# 2) passphrase-protect the identity and commit it
age -p -a -o home/key.txt.age /tmp/key.txt

# 3) put the recipient (age1...) into home/.chezmoi.yaml.tmpl, then re-encrypt
#    every secret with `chezmoi re-add` and remove the plaintext identity
rm -P /tmp/key.txt
```

## Chezmoi Data

### Amzn AL2 Linux

```json
{
  "chezmoi": {
    "arch": "amd64",
    "args": [
      "./bin/chezmoi",
      "data"
    ],
    "cacheDir": "/home/simoju/.cache/chezmoi",
    "configFile": "/home/simoju/.config/chezmoi/chezmoi.toml",
    "executable": "/local/home/simoju/bin/chezmoi",
    "fqdnHostname": "dev-dsk-simoju-2a-d3235f40.us-west-2.amazon.com",
    "gid": "100",
    "group": "amazon",
    "homeDir": "/home/simoju",
    "hostname": "dev-dsk-simoju-2a-d3235f40",
    "kernel": {
      "osrelease": "5.4.196-119.356.amzn2int.x86_64",
      "ostype": "Linux",
      "version": "#1 SMP Wed May 25 23:50:13 UTC 2022"
    },
    "os": "linux",
    "osRelease": {
      "ansiColor": "0;33",
      "cpeName": "cpe:2.3:o:amazon:amazon_linux:2:-:internal",
      "homeURL": "https://amazonlinux.com/",
      "id": "amzn",
      "idLike": "centos rhel fedora",
      "name": "Amazon Linux",
      "prettyName": "Amazon Linux 2",
      "variant": "internal",
      "version": "2",
      "versionID": "2"
    },
    "sourceDir": "/home/simoju/.local/share/chezmoi",
    "uid": "12635057",
    "username": "simoju",
    "version": {
      "builtBy": "goreleaser",
      "commit": "c2fc69d68a87620c5f166573d50958da35a1033e",
      "date": "2022-07-17T17:36:27Z",
      "version": "2.19.0"
    },
    "windowsVersion": {},
    "workingTree": "/home/simoju/.local/share/chezmoi"
  }
}
```

### M1 Mac OSX

```json
{
  "chezmoi": {
    "arch": "arm64",
    "args": [
      "chezmoi",
      "data"
    ],
    "cacheDir": "/Users/simoju/.cache/chezmoi",
    "configFile": "/Users/simoju/.config/chezmoi/chezmoi.yaml",
    "executable": "/opt/homebrew/bin/chezmoi",
    "fqdnHostname": "",
    "gid": "20",
    "group": "staff",
    "homeDir": "/Users/simoju",
    "hostname": "f4d4886b2527",
    "kernel": {},
    "os": "darwin",
    "osRelease": {},
    "sourceDir": "/Users/simoju/.local/share/chezmoi/home",
    "uid": "504",
    "username": "simoju",
    "version": {
      "builtBy": "Homebrew",
      "commit": "89f8b0ea0aa4e3add6e1bd2706d3db22373968c8",
      "date": "2022-06-23T16:19:01Z",
      "version": "2.18.1"
    },
    "windowsVersion": {},
    "workingTree": "/Users/simoju/.local/share/chezmoi"
  },
  "config_state": {
    "headless": false,
    "minimal": true,
    "secrets": false
  }
}
```
