fish_add_path --path "$HOME/.config/agency/CurrentVersion"
fish_add_path --path --append "$HOME/.cdp/cdecli"
if not status is-interactive
    return
end
alias bb 'bitbake obmc-phosphor-image'
alias bbc bbclean

function bbclean
    set -l tasks
    for recipe in $argv
        set -a tasks "$recipe:do_clean" "$recipe:do_cleansstate"
    end
    bitbake $tasks
end
function bbdeploy
    if test (count $argv) -lt 3
        echo "Usage: bbdeploy <host> <port> <recipe>..." >&2
        return 2
    end
    set -l host "$argv[1]"
    set -l port "$argv[2]"
    set -l recipes $argv[3..]
    ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$host:$port"; or return
    bitbake $recipes; or return
    for recipe in $recipes
        devtool deploy-target -e "$HOME/scripts/ssh-into-bmc" "$recipe" "admin@$host" -P "$port" --no-preserve --strip -s; or return
    end
end
function bbdbgrefresh
    if not set -q BUILDDIR
        echo "bbdbgrefresh: BUILDDIR must be set by your build environment" >&2
        return 2
    end
    for recipe in $argv
        set -l base "$BUILDDIR/tmp/work/armv7ahf-vfpv4d16-openbmc-linux-gnueabi/$recipe/1.0+gitAUTOINC+7f9e3f09b4-r1/packages-split"
        if not test -d "$base/$recipe"; or not test -d "$base/$recipe-dbg"
            echo "bbdbgrefresh: packages not found under $base" >&2
            return 1
        end
        for directory in "$base/$recipe"/*/ "$base/$recipe-dbg"/*/
            cp -a "$directory" "$BUILDDIR/debugfs"; or return
        end
    end
end

for helper in ado-push ado-pull ado-fetch
    function $helper --inherit-variable helper
        dotfiles-helper ado "$helper" $argv
    end
end
for helper in ssh-rm ssh-bmc ssh-bmc-su scp-bmc scp-bmc-su sftp-rm rmPortForward ip2dec clean_control_chars filter_output format_line change-rm-password change-bmc-password change-bmc-password-su
    function $helper --inherit-variable helper
        dotfiles-helper rm "$helper" $argv
    end
end
function rm_ssh
    env SSH_ASKPASS_REQUIRE=force SSH_ASKPASS="$HOME/.rm-pass" ssh -oLogLevel=error -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oServerAliveInterval=60 -c aes256-cbc $argv
end
function ssh-port-tunnelling
    echo "ssh-port-tunnelling is not implemented; use rmPortForward or ssh -L" >&2
    return 2
end
