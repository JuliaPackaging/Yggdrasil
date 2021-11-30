# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libaio"
version = v"0.3.112"

# Collection of sources required to complete build
sources = [
    GitSource("https://pagure.io/libaio.git", "d025927efa75a0d1b46ca3a5ef331caa2f46ee0e")
]

dependencies = Dependency[]

# Bash recipe for building across all platforms
script = raw"""
cd libaio

make -j${nproc} install prefix=${prefix}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> Sys.islinux(p), supported_platforms(;experimental=true))

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libaio", :libaio)
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
