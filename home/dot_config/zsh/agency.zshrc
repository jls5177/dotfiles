# Agency managed PATH (Microsoft)
if [[ ":${PATH}:" != *":$HOME/.config/agency/CurrentVersion:"* ]]; then
    export PATH="$HOME/.config/agency/CurrentVersion:${PATH}"
fi
