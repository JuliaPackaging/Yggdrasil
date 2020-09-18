# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "cli"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/cli/cli.git", "b2e36a0979a06b94bf364552a856c166cd415234")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd cli/
make
mkdir ${bindir}
mv ./bin/gh ${bindir}/gh
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
    Windows(:i686),
    Windows(:x86_64)
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("gh", :gh)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers = [:go, :c])
