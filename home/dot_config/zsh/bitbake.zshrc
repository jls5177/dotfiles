alias bb='bitbake obmc-phosphor-image'

bbclean() {
  local args=()

  for recipe in $*
  do
    #echo "Adding $recipe"
    args+=("${recipe}:do_clean")
    args+=("${recipe}:do_cleansstate")
  done

  #bitbake -c clean $recipe && bitbake -c cleansstate $recipe
  #bitbake ${recipe}:do_clean ${recipe}:do_cleansstate
  echo bitbake ${args[@]}
  bitbake ${args[@]}
}

alias bbc='bbclean'

RM_SSH_OPS=("-oLogLevel=error")
RM_SSH_OPS+=("-oStrictHostKeyChecking=no")
RM_SSH_OPS+=("-oUserKnownHostsFile=/dev/null")

bbdeploy() {
  local host="${1:?host address is required}"
  local port="${2:?port number is required}"
  shift;
  shift;

  ssh-keygen -f "$HOME/.ssh/known_hosts" -R "${host}:${port}"

  echo bitbake ${@}
  bitbake ${@}

  for recipe in $*
  do
    echo devtool deploy-target -e '/home/simonjus/scripts/ssh-into-bmc' ${recipe} admin@${host} -P ${port} --no-preserve --strip -s
    devtool deploy-target -e '/home/simonjus/scripts/ssh-into-bmc' ${recipe} admin@${host} -P ${port} --no-preserve --strip -s
  done
}

bbdbgrefresh() {
	  for recipe in $*
	do
		echo "Refreshing $recipe"
		cp -a $BUILDDIR/tmp/work/armv7ahf-vfpv4d16-openbmc-linux-gnueabi/${recipe}/1.0+gitAUTOINC+7f9e3f09b4-r1/packages-split/${recipe}/*(/) $BUILDDIR/debugfs
		cp -a $BUILDDIR/tmp/work/armv7ahf-vfpv4d16-openbmc-linux-gnueabi/${recipe}/1.0+gitAUTOINC+7f9e3f09b4-r1/packages-split/${recipe}-dbg/*(/) $BUILDDIR/debugfs
	done
}
