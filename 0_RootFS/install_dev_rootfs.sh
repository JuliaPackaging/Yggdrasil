#!/bin/bash
# Build rootfs

BB_PATH=$(julia -e 'using BinaryBuilder; print(abspath(dirname(dirname(pathof(BinaryBuilder)))))')

# If `Artifacts.toml` is not writable, complain that we're not using a dev'ed version
if [[ ! -w "${BB_PATH}/Artifacts.toml" ]]; then
    echo "ERROR: BinaryBuilder checkout does not seem writable!"
fi

# Install only a subset of the full set of projects if this is set
PROJECTS="Rootfs GCCBootstrap LLVMBootstrap PlatformSupport"
if [[ -n "$1" ]] && [[ $1 == *"${PROJECTS}"* ]]; then
    PROJECTS="$1"
fi

# Copy everything over to ~/.julia/dev/BinaryBuilder/deps/downloads
for proj in $PROJECTS; do
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
