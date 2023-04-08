#!/bin/bash

# riscv64 is broken
cpuarchs="amd64 arm32v5 arm32v7 arm64v8 i386 mips64le ppc64le riscv64 s390x"

for cpuarch in $cpuarchs; do
    tag="generate-h5tinit:debian-$cpuarch"
    docker build --file generate-h5tinit.dockerfile --build-arg cpuarch="$cpuarch" --progress plain --tag "$tag" .
    docker run --rm "$tag" | tee "H5Tinit-debian-${cpuarch}.c"
done
