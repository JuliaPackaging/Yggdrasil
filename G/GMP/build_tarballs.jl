# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# Collection of sources required to build GMP
name = "GMP"
version = v"6.2.0"

sources = [
    ArchiveSource("https://gmplib.org/download/gmp/gmp-$(version).tar.bz2",
                  "f51c99cb114deb21a60075ffb494c1a210eb9d7cb729ed042ddb7de9534451ea"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gmp-*

# Include Julia-carried patches
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/gmp_alloc_overflow_func.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/gmp-exception.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/gmp-apple-arm64.patch

flags=(--enable-cxx --enable-shared --disable-static)

# On x86_64 architectures, build fat binary
if [[ ${proc_family} == intel ]]; then
    flags+=(--enable-fat)
fi

autoreconf
./configure --prefix=$prefix --build=${MACHTYPE} --host=${target} ${flags[@]}

make -j${nproc}
make install

# On Windows, we need to make sure that the non-versioned dll names exist too
if [[ ${target} == *mingw* ]]; then
    cp -v ${libdir}/libgmp-*.dll "${libdir}/libgmp.dll"
    cp -v ${libdir}/libgmpxx-*.dll "${libdir}/libgmpxx.dll"
fi

# GMP is dual-licensed, install all license files
install_license COPYING*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis([supported_platforms(); Platform("aarch64", "macos")])

# The products that we will ensure are always built
products = [
    LibraryProduct("libgmp", :libgmp),
    LibraryProduct("libgmpxx", :libgmpxx),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6", julia_compat="1.6")
