# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "SDL2"
version = v"2.0.20"

# Collection of sources required to build SDL2
sources = [
    GitSource("https://github.com/libsdl-org/SDL.git", "b424665e0899769b200231ba943353a5fee1b6b6"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SDL2-*/

FLAGS=()
if [[ "${target}" == *-linux-* ]] || [[ "${target}" == *-freebsd* ]]; then
    FLAGS+=(--with-x)
fi

export CPPFLAGS="-I${prefix}/include"
export LDFLAGS="-L${libdir}"

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --enable-shared \
    --disable-static \
    "${FLAGS[@]}"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libSDL2", "SDL2"], :libsdl2)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("Xorg_libX11_jll"),
    Dependency("Xorg_libXcursor_jll"),
    Dependency("Xorg_libXext_jll"),
    Dependency("Xorg_libXinerama_jll"),
    Dependency("Xorg_libXrandr_jll"),
    Dependency("Xorg_libXScrnSaver_jll"),
    Dependency("Libglvnd_jll"),
    Dependency("alsa_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
