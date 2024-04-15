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

bbdeploy() {
  local host="${1:?host address is required}"
  local port="${2:?port number is required}"
  shift;
  shift;

  ssh-keygen -f "$HOME/.ssh/known_hosts" -R "${host}:${port}"

  for recipe in $*
  do
    echo devtool build ${recipe}
    devtool build ${recipe}
  done

  for recipe in $*
  do
    echo devtool deploy-target ${recipe} admin@${host} -P ${port} --no-preserve --strip -s
    devtool deploy-target ${recipe} admin@${host} -P ${port} --no-preserve --strip -s
  done
}
