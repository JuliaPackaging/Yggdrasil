# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "UCX"
version = v"1.7.0"

# Collection of sources required to complete build
sources = [
    "https://github.com/openucx/ucx/releases/download/v1.7.0/ucx-1.7.0.tar.gz" =>
    "6ab81ee187bfd554fe7e549da93a11bfac420df87d99ee61ffab7bb19bdd3371",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd ucx-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --disable-numa
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc),
    Linux(:powerpc64le, libc=:glibc)
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libuct", :libuct),
    LibraryProduct("libucm", :libucm),
    LibraryProduct("libucp", :libucp),
    LibraryProduct("libucs", :libucs),
    ExecutableProduct("ucx_info", :ucx_info)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
