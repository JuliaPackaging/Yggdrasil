#!/bin/bash

set -euxo pipefail

# cpuarch:platform:osversion
cpuarchs=(
    amd64:linux/amd64:12.9
    arm32v5:linux/arm:12.9
    arm32v7:linux/arm:12.9
    arm64v8:linux/arm64:12.9
    i386:linux/i386:12.9
    mips64le:linux/mips64le:12.9
    ppc64le:linux/ppc64le:12.9
    riscv64:linux/riscv64:unstable-20250113
    s390x:linux/s390x:12.9
)

for item in "${cpuarchs[@]}"; do
    IFS=':' read -r cpuarch platform osversion <<< "$item"
    echo "cpuarch=$cpuarch platform=$platform:"
    tag="generate-h5tinit:debian-$cpuarch"
    dockerargs=(
        --file generate-h5tinit.dockerfile
        --build-arg cpuarch="$cpuarch"
        --build-arg osversion="$osversion"
        --platform "$platform"
        --progress plain
        --tag "$tag"
    )
    docker build "${dockerargs[@]}" .
    rm -rf "debian-${cpuarch}"
    mkdir "debian-${cpuarch}"
    docker run --rm "$tag" cat fortran/src/H5fortran_types.F90 | tee "debian-${cpuarch}/H5fortran_types.F90"
    docker run --rm "$tag" cat fortran/src/H5f90i_gen.h | tee "debian-${cpuarch}/H5f90i_gen.h"
    docker run --rm "$tag" cat fortran/src/H5_gen.F90 | tee "debian-${cpuarch}/H5_gen.F90"
    docker run --rm "$tag" cat hl/fortran/src/H5LTff_gen.F90 | tee "debian-${cpuarch}/H5LTff_gen.F90"
    docker run --rm "$tag" cat hl/fortran/src/H5TBff_gen.F90 | tee "debian-${cpuarch}/H5TBff_gen.F90"
    docker run --rm "$tag" cat config.status | tee "debian-${cpuarch}/config.status"
    # docker run --rm "$tag" cat /hdf5/include/H5fortran_types.F90 | tee "debian-${cpuarch}/H5fortran_types.F90"
    # docker run --rm "$tag" cat /hdf5/include/H5f90i_gen.h | tee "debian-${cpuarch}/H5f90i_gen.h"
    # docker run --rm "$tag" cat /hdf5-1.14.5/builddir/fortran/H5_gen.F90 | tee "debian-${cpuarch}/H5_gen.F90"
    # docker run --rm "$tag" cat /hdf5-1.14.5/builddir/hl/fortran/shared/H5LTff_gen.F90 | tee "debian-${cpuarch}/H5LTff_gen.F90"
    # docker run --rm "$tag" cat /hdf5-1.14.5/builddir/hl/fortran/shared/H5TBff_gen.F90 | tee "debian-${cpuarch}/H5TBff_gen.F90"
    # docker run --rm "$tag" cat /hdf5/include/H5config_f.inc | tee "debian-${cpuarch}/H5config_f.inc"
done
