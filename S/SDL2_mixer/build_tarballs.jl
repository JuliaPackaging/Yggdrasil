# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SDL2_mixer"
version = v"2.6.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/libsdl-org/SDL_mixer.git",
              "75f318100d220e236c4fcc5a3d0c9ba33d064f3f"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SDL*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-pic --disable-static
make -j${nproc}
make install
install_license LICENSE.txt
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
