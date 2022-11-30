#!/usr/bin/env julia
using BinaryBuilder, Pkg

name = "extrae"
version = v"4.0.1"
sources = [
    ArchiveSource(
        "https://github.com/bsc-performance-tools/extrae/archive/refs/tags/$(version).tar.gz",
        "e6765eb087be3f3c162e08d65f425de5f26912811392527d56ecd75d4fb6b99d"),
        DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/extrae-*

atomic_patch -p1 ../patches/0001-autoconf-replace-pointer-size-check-by-AC_CHECK_SIZE.patch
atomic_patch -p1 ../patches/0002-autoconf-use-simpler-endianiness-check.patch

autoreconf -fvi
./configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-openmp \
    --without-binutils \
    --without-dyninst \
    --without-mpi \
    --without-papi \
    --without-unwind

make -j${nproc}
make install
"""

platforms = [
    Platform("i686", "Linux"),
    Platform("x86_64", "Linux"),
]

products = [
    LibraryProduct("libseqtrace", :libseqtrace),
    LibraryProduct("libnanostrace", :libnanostrace),
]

dependencies = [
    Dependency("XML2_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
