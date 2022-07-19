# Print a programming excuse on each new shell
excuse() {
  if [ "$(uname -s)" = "Darwin" ]; then
    alias shuf=gshuf
  fi
  $HOME/.config/programmingexcuses/programmingexcuses | cowsay
}

excuse
