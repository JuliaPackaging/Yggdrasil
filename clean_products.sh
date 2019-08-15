#!/bin/bash
cd "$(dirname "${BASH_SOURCE[0]}")"

for parent in *; do
    if [[ ! -d "${parent}" ]]; then
        continue
    fi

    for project in ${parent}/*; do
        if [[ ! -d "${parent}/${project}" ]]; then
            rm -vrf "${parent}/${project}/products"
        fi
    done
done
