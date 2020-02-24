# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CoinUtils"
version = v"2.11.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/coin-or/CoinUtils.git", "d4f2b7f1897b67da6929ab42aa6b1962a388c5b9"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/CoinUtils/

# Remove wrong libtool files
rm -f /opt/${target}/${target}/lib*/*.la

if [[ "${target}" == *-musl* ]]; then
    # This is to fix the following error:
    #    node_heap.cpp:11:22: fatal error: execinfo.h: No such file or directory
    #     #include <execinfo.h>
    # `execinfo.h` is GlibC-specific, not Linux-specific
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/glibc_specific.patch"
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libCoinUtils", :libCoinUtils)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
