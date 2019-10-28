# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "hello_world"
version = v"1.2.3"

# Collection of sources required to complete build
sources = [
    "https://github.com/staticfloat/small_bin/raw/master/socrates.tar.gz" =>
    "e65d2f13f2085f2c279830e863292312a72930fee5ba3c792b14c33ce5c5cc58",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir -p ${prefix}/bin
cc -o ${prefix}/bin/hello_world /usr/share/testsuite/c/hello_world/hello_world.c

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
    Windows(:i686),
    Windows(:x86_64)
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("bin/hello_world", :hello_world)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

