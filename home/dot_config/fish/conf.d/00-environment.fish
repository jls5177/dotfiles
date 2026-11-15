if not command -q brew
    for prefix in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew $HOME/.linuxbrew
        if test -x "$prefix/bin/brew"
            fish_add_path --path "$prefix/bin" "$prefix/sbin"
            break
        end
    end
end
if command -q brew
    brew shellenv fish | source
end
fish_add_path --path --move $HOME/bin $HOME/.local/bin $HOME/scripts
fish_add_path --path --append $HOME/go/bin $HOME/.cargo/bin $HOME/.config/depot_tools $HOME/.fzf/bin
set -gx EDITOR vim
set -gx GOPROXY goproxy.io,direct
set -gx JAVA_TOOLS_OPTIONS -Dlog4j2.formatMsgNoLookups=true
set -gx PYENV_ROOT $HOME/.pyenv
fish_add_path --path "$PYENV_ROOT/bin"

set -l effective $LANG
if set -q LC_ALL; and test -n "$LC_ALL"
    set effective $LC_ALL
end
if test -n "$effective"; and not locale -a | string match -qi -- "$effective"
    set -e LC_ALL
    for candidate in en_US.UTF-8 C.UTF-8 C.utf8 C
        if locale -a | string match -qi -- "$candidate"
            set -gx LANG $candidate
            break
        end
    end
end
