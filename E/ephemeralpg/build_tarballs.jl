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
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("armv7l", "linux"; libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("armv7l", "linux"; libc="musl"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "freebsd"),
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
