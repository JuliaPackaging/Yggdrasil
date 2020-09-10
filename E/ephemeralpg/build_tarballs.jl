# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ephemeralpg"
version = v"3.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://eradman.com/ephemeralpg/code/ephemeralpg-3.0.tar.gz", "70ef314e31c5547f353ea7b2787faafa07adc32dcfaea6f4f1475512c23b0fc8")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ephemeralpg-*
export PREFIX=$prefix
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
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    MacOS(:x86_64),
    FreeBSD(:x86_64),
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("pg_tmp", :pg_tmp),
    ExecutableProduct("getsocket", :getsocket),
    ExecutableProduct("ddl_compare", :ddl_compare),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
