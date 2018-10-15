#!/bin/bash
# Build rootfs

BB_PATH=$(julia -e 'using BinaryBuilder; print(abspath(dirname(dirname(pathof(BinaryBuilder)))))')

# Copy everything over to ~/.julia/dev/BinaryBuilder/deps/downloads
for proj in Rootfs BaseCompilerShard GCC LLVM; do
    if [[ "$1" == "--reverse" ]]; then
        rsync -Pav --size-only --include="${proj}*.tar.gz" --include="${proj}*.squashfs" --exclude='*' "${BB_PATH}/deps/downloads/" "${proj}/products"

        # Make sure .squashfs files are newer than the .tar.gz files, so that we don't accidentally recreate them.
        touch ${proj}/products/*.squashfs
    else
        rsync -Pav --size-only --exclude='*.jl' "${proj}/products/" "${BB_PATH}/deps/downloads"
    fi
done

# Clean out mounts and stale *.sha256 files
if [[ "$1" != "--reverse" ]]; then
    sudo umount ${BB_PATH}/deps/mounts/*
    rm -rf ${BB_PATH}/deps/mounts
    rm -f ${BB_PATH}/deps/downloads/*.sha256

    # Re-generate RootfsHashTable.jl
    ./checksum.jl
fi
