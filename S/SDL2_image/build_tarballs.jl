# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SDL2_image"
version = v"2.0.5"

# Collection of sources required to complete build
sources = [
    "http://www.libsdl.org/projects/SDL_image/release/SDL2_image-2.0.5.zip" =>
    "eee0927d1e7819d57c623fe3e2b3c6761c77c474fe9bc425e8674d30ac049b1c",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd SDL2_image-2.0.5/
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
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    MacOS(:x86_64)
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libSDL2_image", :libsdl2_image)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    PackageSpec(name="SDL2_jll", uuid="ab825dc5-c88e-5901-9575-1e5e20358fcf")
    PackageSpec(name="libwebp_jll", uuid="c5f90fcd-3b7e-5836-afba-fc50a0988cb2")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
