#!/usr/bin/env julia
using BinaryBuilder, Pkg

name = "Extrae"
version = v"4.0.2rc1"
sources = [
    GitSource("https://github.com/bsc-performance-tools/extrae", "5eb2a8ad56aca035b1e13b021a944143e59e6b4a"),
    DirectorySource("$(@__DIR__)/bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/extrae

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0001-autoconf-replace-pointer-size-check-by-AC_CHECK_SIZE.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0002-autoconf-use-simpler-endianiness-check.patch

autoreconf -fvi
./configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --without-dyninst \
    --disable-nanos \
    --disable-smpss \
    --without-mpi \
    --with-binutils=$prefix \
    --with-unwind=$prefix \
    --with-xml-prefix=$prefix \
    --with-papi=$prefix

make -j${nproc}
make install
"""

platforms = [
    Platform("x86_64", "Linux"),
]

products = [
    LibraryProduct("libseqtrace", :libseqtrace),
    ExecutableProduct("extrae-cmd", :extrae_cmd),
    ExecutableProduct("extrae-header", :extrae_header),
    ExecutableProduct("extrae-loader", :extrae_loader),]

dependencies = [
    Dependency("Binutils_jll"),
    Dependency("LibUnwind_jll"),
    Dependency("PAPI_jll"),
    Dependency("XML2_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
