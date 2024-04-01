#!/bin/bash

set -euxo pipefail

# cpuarchs="amd64 arm32v5 arm32v7 arm64v8 i386 mips64le ppc64le s390x"
# Note: `riscv64` is only available for Debian `unstable`
cpuarchs="riscv64"

for cpuarch in $cpuarchs; do
    tag="generate-h5tinit:debian-$cpuarch"
    docker build --file generate-h5tinit.dockerfile --build-arg cpuarch="$cpuarch" --progress plain --tag "$tag" .
    rm -rf "debian-${cpuarch}"
    mkdir "debian-${cpuarch}"
    docker run --rm "$tag" cat fortran/src/H5fortran_types.F90 | tee "debian-${cpuarch}/H5fortran_types.F90"
    docker run --rm "$tag" cat fortran/src/H5f90i_gen.h | tee "debian-${cpuarch}/H5f90i_gen.h"
    docker run --rm "$tag" cat fortran/src/H5_gen.F90 | tee "debian-${cpuarch}/H5_gen.F90"
    docker run --rm "$tag" cat hl/fortran/src/H5LTff_gen.F90 | tee "debian-${cpuarch}/H5LTff_gen.F90"
    docker run --rm "$tag" cat hl/fortran/src/H5TBff_gen.F90 | tee "debian-${cpuarch}/H5TBff_gen.F90"
    docker run --rm "$tag" cat config.status | tee "debian-${cpuarch}/config.status"
done
