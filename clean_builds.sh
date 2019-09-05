#!/bin/bash
cd "$(dirname "${BASH_SOURCE[0]}")"

for parent in *; do
    if [[ ! -d "${parent}" ]]; then
        continue
    fi

    for project in ${parent}/*; do
        if [[ -d "${project}/build" ]]; then
            echo "Removing ${project}/build"
            rm -rf "${project}/build"
        fi
    done
done
