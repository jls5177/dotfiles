# Tiling Window Manager on OS X

[Yabai](https://github.com/koekeishiya/yabai) is a tiling window
manager for Mac OS X. It is similar to I3 on Linux distros but does
not have as many features. My configuration uses
[SKHD](https://github.com/koekeishiya/skhd) for adding
hotkeys to perform common Yabai actions (move focus/window,
create/delete spaces, ...). In addition, I am currently using
[Spacebar](https://github.com/somdoron/spacebar) to replace the
Menubar.

## Steps to replicate my TWM configuration

Copy my TWM configs:

    mkdir -p $HOME/.config/{yabai,skhd,spacebar}
    cp -r .config/{yabai,skhd,spacebar} $HOME/.config/

Then either use my Brewfile to install all of the required package
(and start the various services) or manually run the various Homebrew
commands:

### Install using Brewfile

Here is how to use my Brewfile:

    # Copy the file to your home directory
    cp .Brewfile $HOME/.Brewfile

    # (Optional) Edit the file to add/remove packages
    $EDITOR $HOME/.Brewfile

    # Install packages
    brew bundle install

### Install manually

Run the following command to install Yabi, SKHD, and Spacebar:

    brew install koekeishiya/formulae/yabai skhd somdoron/formulae/spacebar

Start the Yabai services:

    brew services start yabai
    brew services start skhd

## Yabai Dock integration

Yabai requires installing a script runner into the Dock app to perform the various
space manipulations. This requires you to disable specific features of the System
Integrity Protection (SIP). You can follow the steps on the Yabai Wiki page:
https://github.com/koekeishiya/yabai/wiki/Disabling-System-Integrity-Protection 

Once it is disabled you need to run the following command to install the scripting addition:

    # install the scripting addition
    sudo yabai --install-sa

    # load the scripting addition
    killall Dock

## Yabai upgrade steps

You can find the latest upgrade steps on the Yabai Wiki:

https://github.com/koekeishiya/yabai/wiki/Installing-yabai-(latest-release)#updating-to-the-latest-release

# Bootstrap a new system

Here are the steps to bootstrap a new system. If running a Darwin 
system then Homebrew will be needed to install the various packages.

Note: Nobody besides myself should run these commands as many of the config files have my personal details (i.e. git username and email).

### Install homebrew (Mac OS X only)

    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

### Install [yadm](https://github.com/TheLocehiliosan/yadm)

    # If on a Mac, use homebrew to install YADM 
    brew install yadm

    # Tell YADM the repo to clone from
    yadm clone https://github.com/jls5177/dotfiles.git

### Install Brew Bundle

Note: this step is performed during the YADM bootstrap process but is
added here for posterity.

    brew bundle install
    brew bundle cleanup --force

