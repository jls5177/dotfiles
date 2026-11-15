# Authentication is provided by the configured Git credential helper.
ado-push() {
    local repo branch remote force="" delete="" ref
    git rev-parse --git-dir >/dev/null 2>&1 || return 1
    repo="${PWD##*/}"
    branch="$(git symbolic-ref --short HEAD)" || return
    remote="$(git config --local "branch.${branch}.remote")"
    remote="${remote:-https://azurecsi.visualstudio.com/OpenBMC/_git/${repo}}"
    ref="${branch}:refs/heads/${branch}"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -a) remote="https://azurecsi.visualstudio.com/OpenBMC/_git/${repo}" ;;
            -d) delete="-d"; ref="${branch}" ;;
            -f) force="--force" ;;
            *) echo "Usage: ado-push [-f] [-a] [-d]" >&2; return 1 ;;
        esac
        shift
    done
    local args=()
    [[ -z "$delete" ]] || args+=("$delete")
    [[ -z "$force" ]] || args+=("$force")
    git push "$remote" "${args[@]}" "$ref"
}

ado-pull() {
    local repo="${PWD##*/}" branch remote
    local merge_args=(--ff)
    git rev-parse --git-dir >/dev/null 2>&1 || return 1
    branch="$(git symbolic-ref --short HEAD)" || return
    remote="$(git config --local "branch.${branch}.remote")"
    remote="${remote:-https://azurecsi.visualstudio.com/OpenBMC/_git/${repo}}"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -a) remote="https://azurecsi.visualstudio.com/OpenBMC/_git/${repo}" ;;
            -f) merge_args=(-X theirs) ;;
            *) echo "Usage: ado-pull [-f] [-a]" >&2; return 1 ;;
        esac
        shift
    done
    git fetch "$remote" "refs/heads/${branch}" && git merge "${merge_args[@]}" FETCH_HEAD
}

ado-fetch() {
    local repo="${PWD##*/}"
    if [[ $# -ne 1 ]]; then
        echo "Usage: ado-fetch <branch>" >&2
        return 1
    fi
    git fetch "https://azurecsi.visualstudio.com/OpenBMC/_git/${repo}" "refs/heads/$1" &&
        git branch "$1" FETCH_HEAD
}
