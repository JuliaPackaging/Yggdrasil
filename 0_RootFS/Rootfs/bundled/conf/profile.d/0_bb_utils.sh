# Echo but only if we are set to be VERBOSE
vecho() {
	if [ "${VERBOSE}" = "true" ]; then
		echo "$@"
	fi
}

vecho_red() {
	vecho "$@" >&2
}

# Quiet tools
qfind() {
    find "$@" 2>/dev/null
}
qwhich() {
    which "$@" 2>/dev/null
}

# Save bash history (and optionally echo it out as it happens)
save_history() {
    # Skip special commands
    if [[ "${BASH_COMMAND}" == trap* ]] || [[ "${BASH_COMMAND}" == false ]]; then
        return
    fi
	vecho_red " ---> ${BASH_COMMAND}"
    history -s "${BASH_COMMAND}"
    history -a
}

# Save our environment into `/meta/.env`, eliminating read-only variables
# so that this file can be sourced upon entering a debug shell.
save_env() {
	set +x
	set > /meta/.env
	# Ignore read-only variables
	for l in BASHOPTS BASH_VERSINFO UID EUID PPID SHELLOPTS; do
		grep -v "^$l=" /meta/.env > /meta/.env2
		mv /meta/.env2 /meta/.env
	done
	echo "cd $(pwd)" >> /meta/.env
}

if [ -f /meta/.env ]; then
	vecho_red "Loading previous environment..."
	source /meta/.env
fi

