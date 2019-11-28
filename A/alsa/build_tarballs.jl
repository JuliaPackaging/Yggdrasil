# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "alsa"
version = v"1.2.1-1"

# Collection of sources required to complete build
sources = [
    "ftp://ftp.alsa-project.org/pub/lib/alsa-lib-1.2.1.1.tar.bz2" =>
    "c95ac63c0aad43a6ac457d960569096b0b2ef72dc4e3737e77e3e2de87022cec",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd alsa-lib-1.2.1.1/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
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
    LibraryProduct("libasound", :libasound),
    LibraryProduct("libatopology", :libatopology)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

