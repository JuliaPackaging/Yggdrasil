# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SDL2_net"
version = v"2.2.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://libsdl.org/projects/SDL_net/release/SDL2_net-$(version).tar.gz",
                  "4e4a891988316271974ff4e9585ed1ef729a123d22c08bd473129179dc857feb"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SDL*/

mkdir build && cd build
../configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# Missing dep at the moment
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)
filter!(p -> arch(p) != "riscv64", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libSDL2_net", "SDL2_net"], :libSDL2_net)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="SDL2_jll", uuid="ab825dc5-c88e-5901-9575-1e5e20358fcf"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
