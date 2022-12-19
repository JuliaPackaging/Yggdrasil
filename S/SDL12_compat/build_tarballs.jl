# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SDL12_compat"
version = v"1.2.60"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/libsdl-org/sdl12-compat.git", "43887001c05c64eb23eb5312c0f62e9841618700")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd sdl12-compat/
mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DSDL12TESTS=OFF -DSDL12DEVEL=ON ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms() 

x11_platforms = filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct(["SDL", "libSDL"], :libSDL)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="SDL2_jll", uuid="ab825dc5-c88e-5901-9575-1e5e20358fcf"))
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid="c4d99508-4286-5418-9131-c86396af500b");
		     platforms=x11_platforms)
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", dont_dlopen=true)
