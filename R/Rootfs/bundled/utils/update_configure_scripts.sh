#!/bin/bash

RECONF_TARGETS=()
function replace_files()
{
    echo "Searching for ${1} files to replace..."
	FILES=$(find . -type f -name ${1})
	if [[ -n "${FILES}" ]]; then
		for f in ${FILES}; do
		    cp -vf "${2}/${1}" ${f}
            RECONF_TARGETS+=("$(dirname "${f}")")
		done
	fi
}

replace_files config.guess /usr/local/share/configure_scripts
replace_files config.sub /usr/local/share/configure_scripts

if [[ "$1" == --reconf ]]; then
    for d in "${RECONF_TARGETS[@]}"; do
        echo "Running autoreconf in $d..."
        (cd "$d"; autoreconf -i -f)
    done
fi
