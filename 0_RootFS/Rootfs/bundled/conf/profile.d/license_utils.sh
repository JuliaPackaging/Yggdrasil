# Function to automatically install license files at the end of the build
auto_install_license () {
    if [[ ! -d "${prefix}/share/licenses/${SRC_NAME}" ]]; then
        # The license directory doesn't exist, let's find all licenses

        DIR="${WORKSPACE}/srcdir"
        # Build the list of known names for license files
        LICENSE_FILENAMES=()
        for bname in COPYING COPYRIGHT LICENCE LICENSE ; do
            for extension in "" .md .rtf .txt; do
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
            dirs=$(qfind "${DIR}" -mindepth 1 -maxdepth 1 -type d -path "${DIR}/patches" -prune -o -print)
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

