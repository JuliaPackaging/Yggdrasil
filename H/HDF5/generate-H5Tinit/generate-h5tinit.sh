#!/bin/bash

set -euxo pipefail

# Possible values for osversion:gccversion:
#   11.11:{9,10,11}
#   12.12:{11,12}
#   13.1:{12,13,14}

# cpuarch:platform:osversion:gccversion
cpuarchs=(
    amd64:linux/amd64:13.1:12
    # arm32v5:linux/arm:13.1:12
    arm32v7:linux/arm:13.1:12
    arm64v8:linux/arm64:13.1:12
    i386:linux/i386:13.1:12
    # mips64le:linux/mips64le
    ppc64le:linux/ppc64le:13.1:12
    riscv64:linux/riscv64:13.1:12
    # s390x:linux/s390x
)

# HDF5 version
commit=2ff6c6497c2962c78e489b59a4b5b0e2b136a2c1

for item in "${cpuarchs[@]}"; do
    IFS=':' read -r cpuarch platform osversion gccversion <<< "${item}"
    {
        echo "cpuarch=${cpuarch} platform=${platform} osversion=${osversion} gccversion=${gccversion}:"
        tag="generate-h5tinit:debian-${cpuarch}"
        dockerargs=(
            --file generate-h5tinit.dockerfile
            --build-arg commit="${commit}"
            --build-arg cpuarch="${cpuarch}"
            --build-arg osversion="${osversion}"
            --build-arg gccversion="${gccversion}"
            --platform "${platform}"
            --progress plain
            --tag "${tag}"
        )
        docker build "${dockerargs[@]}" .
        rm -rf "debian-${cpuarch}"
        mkdir "debian-${cpuarch}"
        # for file in \
        #     fortran/src/CMakeFiles/H5_buildiface.dir/H5_buildiface.F90-pp.f90 \
        #     hl/fortran/src/CMakeFiles/H5HL_buildiface.dir/H5HL_buildiface.F90-pp.f90
        # do
        #     docker run --rm "${tag}" cat builddir/${file} >"debian-${cpuarch}/$(basename ${file})"
        # done
        for file in \
            fortran/H5_gen.F90 \
            fortran/H5f90i_gen.h \
            fortran/H5fortran_types.F90 \
            fortran/test/tf_gen.F90 \
            hl/fortran/H5LTff_gen.F90 \
            hl/fortran/H5TBff_gen.F90
        do
            docker run --rm "${tag}" cat builddir/${file} >"debian-${cpuarch}/$(basename ${file})"
        done
    } 2>&1 | tee "debian-${cpuarch}.log"
done
