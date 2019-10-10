# Echo but only if we are set to be VERBOSE
vecho() {
	if [ "${VERBOSE}" = "true" ]; then
		echo "$@"
	fi
}

vecho_red() {
	vecho "$@" >&2
}

# Save bash history (and optionally echo it out as it happens)
save_history() {
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

# We do a little sleight-of-hand here; we want to build inside of a tmpfs
# because `srcdir` might be mapped in through a networked filesystem, which
# totally wrecks our I/O performance.  So what we do instead is bind-mount
# `srcdir` to another location so that we can always get at it, copy its
# contents to a new tmpfs we mount at the location of `srcdir`, then when
# we exit on an error, we copy everything back over again
tmpify_srcdir() {
	vecho "Copying srcdir to tmpfs..."
	mkdir -p $WORKSPACE/.true_srcdir
	mount --bind $WORKSPACE/srcdir $WORKSPACE/.true_srcdir
	mount -t tmpfs tmpfs $WORKSPACE/srcdir
	cp -a $WORKSPACE/.true_srcdir/. $WORKSPACE/srcdir

	# We may have changed what pwd() means out from underneath ourselves
	cd $(pwd)
}

# Copy our tmpfs version of `srcdir` back onto disk.
save_srcdir() {
	vecho_red "Saving srcdir due to previous error..."
	rsync -rlptD $WORKSPACE/srcdir/ $WORKSPACE/.true_srcdir --delete
}

if [ -f /meta/.env ]; then
	vecho_red "Loading previous environment..."
	source /meta/.env
fi

# Quiet find
qfind() {
    find "$@" 2>/dev/null
}

# Function to install license files
install_license () {
    if [ $# -eq 0 ]; then
        echo "Usage: install_license license_file1.txt [license_file2.md, license_file3.rtf, ...]" >&2
        exit 1
    fi
    for file in "$@"; do
        DEST="${prefix}/share/licenses/${SRC_NAME}/$(basename "${file}")"
        echo "Installing license file \"$file\" to \"${DEST}\"..."
        install -Dm644 "${file}" "${DEST}"
    done
}
