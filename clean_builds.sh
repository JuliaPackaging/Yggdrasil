#!/bin/bash
cd "$(dirname "${BASH_SOURCE[0]}")"

# First, unmount everything
for mount_dir in $(find . -type d -name mounts); do
    echo "Unmounting ${mount_dir}/*"
    sudo umount ${mount_dir}/*
done

for parent in *; do
    if [[ ! -d "${parent}" ]]; then
        continue
    fi

    for project in ${parent}/*; do
        if [[ -d "${project}/build" ]]; then
            echo "Removing ${project}/build"
            rm -rf "${project}/build"
        fi

        for subproject in ${project}/*; do
            if [[ -d "${subproject}/build" ]]; then
                echo "Removing ${subproject}/build"
                rm -rf "${subproject}/build"
            fi
        done
    done
done
