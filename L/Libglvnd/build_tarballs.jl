# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg.BinaryPlatforms

name = "Libglvnd"
version = v"1.2.0"

# Collection of sources required to build Libglvnd
sources = [
    "https://github.com/NVIDIA/libglvnd/releases/download/v$(version)/libglvnd-$(version).tar.gz" =>
    "2dacbcfa47b7ffb722cbddc0a4f1bc3ecd71d2d7bb461bceb8e396dc6b81dc6d",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libglvnd-*/
./configure --prefix=${prefix} --host=${target} \
    CPPFLAGS="-I${prefix}/include" \
    CFLAGS="-Wno-unused-command-line-argument"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if p isa Union{Linux,FreeBSD}]

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libEGL", :libEGL),
    LibraryProduct("libGLdispatch", :libGLdispatch),
    LibraryProduct("libGLESv1_CM", :libGLESv1_CM),
    LibraryProduct("libGLESv2", :libGLESv2),
    LibraryProduct("libGL", :libGL),
    LibraryProduct("libGLX", :libGLX),
    LibraryProduct("libOpenGL", :libOpenGL),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "X11_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
