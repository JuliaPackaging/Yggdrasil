#!/bin/bash

# Install license files

if [ $# -eq 0 ]; then
    echo "Usage: install_license license_file1.txt [license_file2.md, license_file3.rtf, ...]" >&2
    exit 1
fi
for file in "$@"; do
    DEST="${prefix}/share/licenses/${SRC_NAME}/$(basename "${file}")"
    echo "Installing license file \"$file\" to \"${DEST}\"..."
    install -Dm644 "${file}" "${DEST}"
done
