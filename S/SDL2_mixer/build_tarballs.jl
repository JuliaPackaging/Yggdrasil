# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SDL2_mixer"
version = v"2.6.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/libsdl-org/SDL_mixer/releases/download/release-$(version)/SDL2_mixer-$(version).tar.gz",
                  "f94a4d3e878cb191c386a714be561838240012250fe17d496f4ff4341d59a391"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SDL2_mixer*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-pic --disable-static
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libSDL2_mixer", "SDL2_mixer"], :libsdl2_mixer),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="SDL2_jll", uuid="ab825dc5-c88e-5901-9575-1e5e20358fcf")),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
