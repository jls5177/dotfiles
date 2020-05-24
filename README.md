# Shell Configuration

### Install homebrew

    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

### Install [yadm](https://github.com/TheLocehiliosan/yadm)

    brew install yadm
    yadm clone https://github.com/jls5177/dotfiles.git

### Install Brew Bundle (should be bootstrapped by YADM)

#### OSX

    brew bundle install
    brew bundle cleanup --force

