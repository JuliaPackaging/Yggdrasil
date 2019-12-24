# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libnl"
version = v"3.5.0"

# Collection of sources required to complete build
sources = [
    "https://github.com/thom311/libnl/releases/download/libnl3_5_0/libnl-3.5.0.tar.gz" =>
    "352133ec9545da76f77e70ccb48c9d7e5324d67f6474744647a7ed382b5e05fa",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libnl-*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf)
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libnl", :libnl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

