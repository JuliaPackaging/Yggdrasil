#!/bin/bash

# First, build the rootfs
#./build_rootfs.sh

PROJECTS="${1:-Rootfs PlatformSupport GCCBootstrap LLVMBootstrap}"

# Next, upload all .tar.gz and .squashfs files in Rootfs, BaseCompilerShard, GCC and LLVM:
for proj in ${PROJECTS}; do
    aws s3 sync --acl public-read --exclude=\* --include=\*.squashfs --include=\*.tar.gz ${proj}/products/ s3://julialangmirror/binarybuilder/
done
