# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SDL2_mixer"
version = v"2.0.4"

# Collection of sources required to complete build
sources = [
    "http://www.libsdl.org/projects/SDL_mixer/release/SDL2_mixer-2.0.4.tar.gz" =>
    "b4cf5a382c061cd75081cf246c2aa2f9df8db04bdda8dcdc6b6cca55bede2419",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SDL2_mixer-*/
export CPPFLAGS="-I${prefix}/include" 
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-pic 
make -j${nproc}
make install
if [[ "${target}" == *-freebsd* ]]; then
    # We need to manually build the shared library for FreeBSD
    cd "${libdir}"
    ar x libSDL2_mixer.a
    cc -shared -o libSDL2_mixer.${dlext} *.o
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct(["libSDL2_mixer", "SLD2_mixer"], :libsdl2_mixer)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    PackageSpec(name="SDL2_jll", uuid="ab825dc5-c88e-5901-9575-1e5e20358fcf")
    PackageSpec(name="libvorbis_jll", uuid="f27f6e37-5d2b-51aa-960f-b287f2bc3b7a")
    PackageSpec(name="FLAC_jll", uuid="1d38b3a6-207b-531b-80e8-c83f48dafa73")
    PackageSpec(name="mpg123_jll", uuid="3205ef68-7822-558b-ad0d-1b4740f12437")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
