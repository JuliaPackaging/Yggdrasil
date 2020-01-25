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
cd $WORKSPACE/srcdir/SDL2_image-*/
export CPPFLAGS="-I${prefix}/include"
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-pic
make -j${nproc}
make install
if [[ "${target}" == *-freebsd* ]]; then
    # We need to manually build the shared library for FreeBSD
    cd "${libdir}"
    ar x libSDL2_image.a
    cc -shared -o libSDL2_image.${dlext} *.o
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct(["libSDL2_image", "SDL2_image"], :libsdl2_image)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    PackageSpec(name="SDL2_jll", uuid="ab825dc5-c88e-5901-9575-1e5e20358fcf")
    PackageSpec(name="libwebp_jll", uuid="c5f90fcd-3b7e-5836-afba-fc50a0988cb2")
    PackageSpec(name="JpegTurbo_jll", uuid="aacddb02-875f-59d6-b918-886e6ef4fbf8")
    PackageSpec(name="libpng_jll", uuid="b53b4c65-9356-5827-b1ea-8c7a1a84506f")
    PackageSpec(name="Libtiff_jll", uuid="89763e89-9b03-5906-acba-b20f662cd828")
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
