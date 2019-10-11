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

# Function to automatically install license files at the end of the build
auto_install_license () {
    if [[ -z "$(qfind "${prefix}/share/licenses/${SRC_NAME}" -mindepth 1)" ]]; then
        # There are no licenses already installed, let's find 'em all

        DIR="${WORKSPACE}/srcdir"
        # Build the list of known names for license files
        LICENSE_FILENAMES=()
        for bname in COPYING COPYRIGHT LICENCE LICENSE ; do
            for extension in "" .md .txt; do
                # These are actually going to be options for `find`
                LICENSE_FILENAMES+=(-iname "${bname}${extension}" -o)
            done
        done
        # Remove the last OR
        unset 'LICENSE_FILENAMES[${#LICENSE_FILENAMES[@]}-1]'

        # First round: look for license files in ${DIR}
        qfind "${DIR}" -maxdepth 1 -type f \( "${LICENSE_FILENAMES[@]}" \) \
              -exec install_license '{}' \;

        if [[ -z "$(qfind "${prefix}/share/licenses/${SRC_NAME}" -mindepth 1)" ]]; then
            # We didn't install anything.  Let's see if there is a single subdir
            # in ${DIR}, if so look for a license file inside it
            dirs=$(qfind "${DIR}" -mindepth 1 -maxdepth 1 -type d)
            # This test is not safe if there are new lines in ${dirs}, but dealing
            # with new lines here would require a bit of extra work, probably not
            # worth the effort, as we can manually install the license if necessary
            if [[ "$(echo "$dirs" | wc -l)" -eq 1 ]]; then
                # Repeat again what we did above
                DIR="${dirs}"
                qfind "${DIR}" -maxdepth 1 -type f \( "${LICENSE_FILENAMES[@]}" \) \
                      -exec install_license '{}' \;
            fi
        fi
    fi
}
