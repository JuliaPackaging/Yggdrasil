# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "lrslib"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/JuliaPolyhedra/lrslib.git",
              "d8b723a2c315614979a8354f9e768d273d14a215"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lrslib/
export C_INCLUDE_PATH=$C_INCLUDE_PATH:$prefix/include/
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    FreeBSD(:x86_64)
]


# The products that we will ensure are always built
products = [
    LibraryProduct("liblrs", :lrslib)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
