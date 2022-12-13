#!/bin/bash

function _ansible_setup_getdir { (
	set +o physical # Don't follow symlinks
# 	echo "me ${me}" >&2
	local basenamed="${me##*/}"
# 	echo "basenamed: ${basenamed}" >&2
	local dirnamed="${me%"$basenamed"}"
# 	echo "dirnamed: ${dirnamed}" >&2
	if [[ -n "${dirnamed}" ]] ; then
		builtin cd "${dirnamed}"
	fi
	local absolute="$(builtin pwd -L)" # -L: Leave symlinks alone
# 	echo "absolute: ${absolute}" >&2
	printf "%s" "${absolute}"
) }

function _ansible_setup_main {
	local me="${BASH_SOURCE[0]}"

	if [[ "$me" == "$0" ]] ; then
		echo "Source this, don't run it" >&2
		exit 1
	fi

	local repo="$(_ansible_setup_getdir)"

	local venv="${repo}/venv/${HOSTNAME}"
	mkdir -p "${venv}"

	if type deactivate &>/dev/null ; then
		deactivate
	fi

	if ! python3 -m virtualenv --version ; then
		echo "We need to install virtualenv!" >&2
		sudo -- apt install python3-virtualenv || return $?
	fi

	if ! [[ -f "${venv}/bin/activate" ]] ; then
		virtualenv -p python3 ${venv} || return $?
	fi

	if [[ -f "${venv}/bin/activate" ]] ; then
		echo "Virtual Environment: ${venv}" >&2
	else
		echo "Don't know where venv is..." >&2
		return 4
	fi

	source "${venv}/bin/activate" || return $?

	if ! type deactivate &>/dev/null ; then
		echo "didn't activate?" >&2
		return 2
	fi

	if [[ "$0" == */bash ]] || ! which ansible-playbook ; then
		pip install --upgrade --upgrade-strategy eager ansible || return $?
	fi

	cfg="${repo}/ansible.cfg"

	if [[ -f "${cfg}" ]] ; then
		echo "Ansible config: ${cfg}" >&2
	else
		echo "Don't know where ansible.cfg is..." >&2
		return 3
	fi
	export ANSIBLE_COW_SELECTION="bunny"
	export ANSIBLE_CONFIG="$cfg"

	ansible-galaxy collection install community.general
	ansible-galaxy collection install community.crypto

}

_ansible_setup_main || return $?
