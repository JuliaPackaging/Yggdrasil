#!/bin/bash

set -euxo pipefail

for dir in debian-amd64 debian-arm32v5 debian-arm32v7 debian-arm64v8 debian-i386 debian-mips64le debian-ppc64le debian-riscv64 debian-s390x;
do
    cp $dir/* ../bundled/files/$dir
done
