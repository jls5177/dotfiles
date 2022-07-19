## Setup a tunnel to your cloud desktop to access Odin credentials
## Taken from Sage: https://sage.amazon.com/questions/87433#597588?
startOdinTunnel() {
  stopOdinTunnel()
  echo "Opening new tunnel..."
  ssh -f -N -M -S /tmp/odintunnelsession -L 2009:127.0.0.1:2009 $USER-clouddesk.aka.corp.amazon.com
}

stopOdinTunnel() {
  if [ -S /tmp/odintunnelsession ]; then
    echo "Closing existing tunnel..."
    ssh -S /tmp/odintunnelsession -O exit $USER-clouddesk.aka.corp.amazon.com
  fi
}