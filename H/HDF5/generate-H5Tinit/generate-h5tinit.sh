#!/bin/bash

# riscv64 is broken
cpuarchs="amd64 arm32v5 arm32v7 arm64v8 i386 mips64le ppc64le riscv64 s390x"

for cpuarch in $cpuarchs; do
    tag="generate-h5tinit:debian-$cpuarch"
    docker build --file generate-h5tinit.dockerfile --build-arg cpuarch="$cpuarch" --progress plain --tag "$tag" .
    docker run --rm "$tag" cat src/H5Tinit.c | tee "H5Tinit-debian-${cpuarch}.c"
    docker run --rm "$tag" cat fortran/src/H5fortran_types.F90 | tee "H5fortran_types-debian-${cpuarch}.F90"
    docker run --rm "$tag" cat fortran/src/H5f90i_gen.h | tee "H5f90i_gen-debian-${cpuarch}.h"
    docker run --rm "$tag" cat fortran/src/H5_gen.F90 | tee "H5_gen-debian-${cpuarch}.F90"
    docker run --rm "$tag" cat config.status | tee "config-debian-${cpuarch}.status"
done
