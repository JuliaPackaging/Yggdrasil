#!/bin/bash

# First, build the rootfs
./build_rootfs.sh

# Next, upload all .tar.gz and .squashfs files in Rootfs, BaseCompilerShard, GCC and LLVM:
for proj in Rootfs BaseCompilerShard GCC LLVM; do
    aws s3 sync --acl public-read --exclude=\* --include=\*.squashfs --include=\*.tar.gz ${proj}/products/ s3://julialangmirror/binarybuilder/
done
for proj in Rootfs BaseCompilerShard GCC LLVM; do
    shasum -a 256 ${proj}/products/*.{tar.gz,squashfs}
done

