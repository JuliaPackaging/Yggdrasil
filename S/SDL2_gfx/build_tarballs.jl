# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SDL2_gfx"
version = v"1.0.3"

# Collection of sources required to complete build
sources = [
    "http://www.ferzkopp.net/Software/SDL2_gfx/SDL2_gfx-1.0.3.tar.gz" =>
    "a4066bd467c96469935a4b1fe472893393e7d74e45f95d59f69726784befd8f8",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd SDL2_gfx-*

if [[ "${target}" == powerpc64le-* ]]; then
    autoreconf -vi
fi

update_configure_scripts
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct(["libSDL2_gfx", "SDL2_gfx"] :libsdl2_gfx)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    PackageSpec(name="SDL2_jll", uuid="ab825dc5-c88e-5901-9575-1e5e20358fcf")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
