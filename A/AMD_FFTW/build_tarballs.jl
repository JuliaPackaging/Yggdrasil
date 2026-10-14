# Copyright Advanced Micro Devices, Inc.
# SPDX-License-Identifier: MIT

using BinaryBuilder, Pkg

name = "AMDFFTW"
version = v"5.3.0"

sources = [
    GitSource("https://github.com/amd/amd-fftw.git",
              "5b72699a06c3cbde5413c117dc1deaa6a071bb8c"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/amd-fftw

FLAGS=(
    --disable-doc
    --enable-sse2
    --enable-avx
    --enable-avx2
    --enable-avx512
    --enable-openmp
    --enable-shared
    --enable-amd-opt
    --enable-dynamic-dispatcher
    --host="${target}"
    --prefix=${prefix}
)

build_amd_fftw()
{
    mkdir "${WORKSPACE}/srcdir/build_${1}"
    cd "${WORKSPACE}/srcdir/build_${1}"

    bash ${WORKSPACE}/srcdir/amd-fftw/configure "${FLAGS[@]}" $2
    make -j${nproc}
    make install
}

build_amd_fftw double
build_amd_fftw float --enable-float

cd ${WORKSPACE}/srcdir/amd-fftw
install_license COPYING COPYRIGHT NOTICES LICENSE
"""

platforms = [
    Platform("x86_64", "linux"; libc = "glibc")
]

products = [
    LibraryProduct("libfftw3", :libfftw3),
    LibraryProduct("libfftw3f", :libfftw3f),
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"14.2.0",
    julia_compat = "1.9",
)
