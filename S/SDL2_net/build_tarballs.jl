# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SDL2_net"
version = v"2.0.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/libsdl-org/SDL_net/archive/refs/tags/release-$(version).tar.gz", "1fefe563ea333a2655c32169d03a376a334cdbe39da51fd424bf5f430dec83f4")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SDL_net*/

mkdir build && cd build

../configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}

make

make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("x86_64", "macos"; ),
    Platform("aarch64", "macos"; )
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libSDL2_net", :libSDL2_net)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="SDL2_jll", uuid="ab825dc5-c88e-5901-9575-1e5e20358fcf"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
