#!/bin/bash

# Pulled from https://code.amazon.com/packages/NetengCSDCM2017/blobs/mainline/--/curuna/scripts/DarylConnect/config.sh
# See also:
#  1) https://wilsonmar.github.io/maximum-limits/
#  2) https://raw.githubusercontent.com/wilsonmar/mac-setup/master/configs/limit.maxfiles.plist
#  3) https://raw.githubusercontent.com/wilsonmar/mac-setup/master/configs/limit.maxproc.plist

echo -e "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
  <plist version=\"1.0\">
    <dict>
      <key>Label</key>
        <string>limit.maxfiles</string>
      <key>ProgramArguments</key>
        <array>
          <string>launchctl</string>
          <string>limit</string>
          <string>maxfiles</string>
          <string>524288</string>
          <string>unlimited</string>
        </array>
      <key>RunAtLoad</key>
        <true/>
      <key>ServiceIPC</key>
        <false/>
    </dict>
  </plist>" | sudo tee /Library/LaunchDaemons/limit.maxfiles.plist > /dev/null

echo -e "<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple/DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
    <dict>
      <key>Label</key>
        <string>limit.maxproc</string>
      <key>ProgramArguments</key>
        <array>
          <string>launchctl</string>
          <string>limit</string>
          <string>maxproc</string>
          <string>2048</string>
          <string>2048</string>
        </array>
      <key>RunAtLoad</key>
        <true />
      <key>ServiceIPC</key>
        <false />
    </dict>
  </plist>" | sudo tee /Library/LaunchDaemons/limit.maxproc.plist > /dev/null

sudo chmod 644 /Library/LaunchDaemons/limit.maxfiles.plist
sudo chmod 644 /Library/LaunchDaemons/limit.maxproc.plist
sudo chown root:wheel /Library/LaunchDaemons/limit.maxfiles.plist
sudo chown root:wheel /Library/LaunchDaemons/limit.maxproc.plist

read -p "You need to reboot your computer for changes to take effect.\nDo you want to reboot now? (Y/N) " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    sudo shutdown -r now
fi
