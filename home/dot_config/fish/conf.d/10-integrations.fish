if not status is-interactive
    return
end

if command -q direnv
    direnv hook fish | source
end
if command -q fnm
    fnm env --use-on-cd --shell fish | source
end
if command -q pyenv
    pyenv init - fish | source
end
if command -q conda
    conda shell.fish hook | source
else
    for prefix in /opt/homebrew /usr/local
        set -l hook "$prefix/Caskroom/miniconda/base/etc/fish/conf.d/conda.fish"
        if test -f "$hook"
            source "$hook"
            break
        end
    end
end
if command -q fzf
    set -l fzf_version (fzf --version | string split ' ')[1]
    if test (string split . "$fzf_version")[1] -gt 0; or test (string split . "$fzf_version")[2] -ge 48
        fzf --fish | source
    else if test -f "$HOME/.fzf/shell/key-bindings.fish"
        source "$HOME/.fzf/shell/key-bindings.fish"
        fzf_key_bindings
    else if set -q HOMEBREW_PREFIX; and test -f "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.fish"
        source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.fish"
        fzf_key_bindings
    else
        echo "dotfiles: fzf needs version 0.48+ or its Fish key-bindings.fish" >&2
    end
end
if command -q pipx
    set -l register (command -s register-python-argcomplete)
    if test -z "$register"; and command -q brew
        set register (brew --prefix pipx)/libexec/bin/register-python-argcomplete
    end
    if test -x "$register"
        "$register" --shell fish pipx | source
    else
        echo "dotfiles: pipx completions require register-python-argcomplete (argcomplete)" >&2
    end
end
if test "$TERM_PROGRAM" = vscode; and command -q code
    set -l integration (code --locate-shell-integration-path fish)
    if test $status -eq 0; and test -f "$integration"
        source "$integration"
    else
        echo "dotfiles: VS Code Fish shell integration could not be located" >&2
    end
end
