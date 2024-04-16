# Helper functions to simplify connecting to RM/R-SCM devices and access BMCs behind these devices
# The password bypass method was taken from the following links
# * https://www.exratione.com/2014/08/bash-script-ssh-automation-without-a-password-prompt/
# * https://github.com/huan/sshpass.sh/blob/master/sshpass.sh

alias rm_ssh="SSH_ASKPASS_REQUIRE=\"force\" SSH_ASKPASS=~/.rm-pass ssh ${RM_SSH_OPS[@]} -o ServerAliveInterval=60 -c aes256-cbc"

RM_SSH_OPS=("-oLogLevel=error")
RM_SSH_OPS+=("-oStrictHostKeyChecking=no")
RM_SSH_OPS+=("-oUserKnownHostsFile=/dev/null")

ssh-rm() {
	SSH_ASKPASS_REQUIRE="force" SSH_ASKPASS=~/.rm-pass ssh ${RM_SSH_OPS[@]} -c aes256-cbc root@${1} ${@:2}
	# sshpass -f ~/.rm-pass ssh ${RM_SSH_OPS[@]} -c aes256-cbc root@${1} ${@:2}
}

ssh-bmc() {
	local port=22
	local host="localhost"

	if (( $# == 1 )); then
		 case $1 in
			(*[^0-9]*) 
				host=$1
				;;
			(*)        
				port=$1
				;;
		esac
		shift
	elif (( $# >= 2 )); then
		case $1 in
			(*[^0-9]*) 
				host=$1
				port=$2
				shift
				shift
				;;
			(*)        
				port=$1
				shift
				;;
		esac
	fi
	gum log --time rfc822 --level info -- "SSH_ASKPASS_REQUIRE=\"force\" SSH_ASKPASS=~/.bmc-pass ssh -p ${port} ${RM_SSH_OPS[@]} admin@${host} ${@}"
	SSH_ASKPASS_REQUIRE="force" SSH_ASKPASS=~/.bmc-pass ssh -p ${port} ${RM_SSH_OPS[@]} admin@${host} ${@}
}

sftp-rm() {
	SSH_ASKPASS_REQUIRE="force" SSH_ASKPASS=~/.rm-pass sftp ${RM_SSH_OPS[@]} -c aes256-cbc root@${1} ${@:2}
}

ip2dec () {
    local a b c d ip=$@
    IFS=. read -r a b c d <<< "$ip"
    printf '%d\n' "$((a * 256 ** 3 + b * 256 ** 2 + c * 256 + d))"
}

rmPortForward() {
	local rm_host=$1
	local blade_id=$2
	local blade_ip="172.17.0.$(($blade_id*4-3))"
	local ssh_port=$((8022 + ($blade_id - 1)*100))
	local https_port=$((8443 + ($blade_id - 1)*100))
	local args=()

	local session_file="/tmp/rm_tunnel_session_$(ip2dec $rm_host)_$ssh_port"
	if [ -S $session_file ]; then
		# ask the user before closing the terminal
		gum confirm "Close existing tunnel" || return

		gum log --time rfc822 --level info -- "Closing existing tunnel... $(cat ${session_file}.args)"
		ssh -S $session_file -O exit $rm_host
		rm -rf ${session_file}.args
	else
		gum log --time rfc822 --level info "Opening new tunnel..."

		args+=("-L$ssh_port:$blade_ip:22")
		args+=("-L$https_port:$blade_ip:443")

		gum log --time rfc822 --level info -- "Port Forward Map" "22 -> $ssh_port" "443 -> $https_port"
		echo "${@}" > ${session_file}.args
		SSH_ASKPASS_REQUIRE="force" SSH_ASKPASS=~/.rm-pass ssh ${RM_SSH_OPS[@]} -f -N -M -S \
			/tmp/rm_tunnel_session_$(ip2dec $rm_host)_$ssh_port ${args[@]} -c aes256-cbc root@${rm_host}
	fi
}
