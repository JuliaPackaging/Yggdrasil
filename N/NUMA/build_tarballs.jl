# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "NUMA"
version = v"2.0.13"

# bump

# Collection of sources required to complete build
sources = [
    "https://github.com/numactl/numactl/releases/download/v2.0.13/numactl-2.0.13.tar.gz" =>
    "991e254b867eb5951a44d2ae0bf1996a8ef0209e026911ef6c3ef4caf6f58c9a",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd numactl-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc} numademo_CFLAGS="-O3 -funroll-loops"
make install
install_license LICENSE.*
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
    LibraryProduct("libnuma", :libnuma),
    ExecutableProduct("numactl", :numactl),
    ExecutableProduct("numastat", :numastat)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
