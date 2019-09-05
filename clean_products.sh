#!/bin/bash
cd "$(dirname "${BASH_SOURCE[0]}")"

for parent in *; do
    if [[ ! -d "${parent}" ]]; then
        continue
    fi

    for project in ${parent}/*; do
        if [[ -d "${project}/products" ]]; then
            echo "Cleaning ${project}/products"
            rm -rf "${project}/products"
        fi
    done
done
