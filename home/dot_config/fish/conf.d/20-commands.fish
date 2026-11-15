if not status is-interactive
    return
end
alias please sudo
alias fucking sudo
alias got git
alias g git
alias gst 'git status'
alias gco 'git checkout'
alias gcb 'git checkout -b'
alias gl 'git pull'
alias gp 'git push'
alias gc 'git commit'
alias gca 'git commit --amend'
alias gb 'git branch'
alias gcl 'git clone'
alias gd 'git diff'
alias ga 'git add'
alias grh 'git reset'
alias v code
alias c code
alias vsc code
alias vsca 'code --add'
alias vscd 'code --diff'
alias vscn 'code --new-window'
alias vscw 'code --wait'
alias vscu 'code --user-data-dir'
alias vscr 'code --reuse-window'
alias vscc 'code --copy-file'
alias vscg 'code --goto'

for operation in add reset::head log diff ignore restore clean stash::show cherry::pick ignore::update ignore::get ignore::list ignore::clean
    set -l helper "forgit::$operation"
    function $helper --inherit-variable helper
        dotfiles-helper forgit "$helper" $argv
    end
end

if not set -q FORGIT_NO_ALIASES; or test -z "$FORGIT_NO_ALIASES"
    set -l names ga grh glo gd gi gcf gclean gss gcp
    set -l operations add reset::head log diff ignore restore clean stash::show cherry::pick
    set -l overrides forgit_add forgit_reset_head forgit_log forgit_diff forgit_ignore forgit_restore forgit_clean forgit_stash_show forgit_cherry_pick
    for i in (seq (count $names))
        set -l name $names[$i]
        if set -q $overrides[$i]
            set name $$overrides[$i]
        end
        set -l operation "forgit::$operations[$i]"
        function $name --inherit-variable operation
            dotfiles-helper forgit "$operation" $argv
        end
    end
end
