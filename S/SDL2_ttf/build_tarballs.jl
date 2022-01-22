# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "SDL2_ttf"
version = v"2.0.18"

# Collection of sources required to build SDL2_ttf
sources = [
    GitSource("https://github.com/libsdl-org/SDL_ttf.git", "3e702ed9bf400b0a72534f144b8bec46ee0416cb"),
    DirectorySource("./bundled"),
]

version = v"2.0.16" # <-- this version number is a lie to build for Julia v1.6

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SDL*/

atomic_patch -p1 ../patches/configure_in-v2.0.15.patch
atomic_patch -p1 ../patches/Makefile_in_dont_build_programs.patch
touch NEWS README AUTHORS ChangeLog
# For some reasons, the first time `autoreconf` may fail,
# but with some encouragement it can do it
autoreconf -vi || autoreconf -vi
export CPPFLAGS="-I${prefix}/include/SDL2"
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --enable-shared \
    --disable-static \
    "${FLAGS[@]}"
make -j${nproc}
make install

if [[ "${target}" == *-mingw* ]]; then
    # As usual, build system for Windows is wrecked
    # and the shared library is not built at all
    cd ${prefix}/lib
    ar x libSDL2_ttf.a
    cc -shared -o ${libdir}/SDL2_ttf.dll SDL_ttf.o ${libdir}/libfreetype-6.dll ${libdir}/SDL2.dll
    rm SDL_ttf.o
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libSDL2_ttf", "SDL2_ttf"], :libsdl2_ttf)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Bzip2_jll"; compat="1.0.8"),
    Dependency("FreeType2_jll"),
    Dependency("Glib_jll"; compat="2.68.1"),
    Dependency("Graphite2_jll"),
    # The following libraries aren't needed for the build, but libSDL2_ttf is
    # dynamically linked to them regardless.
    Dependency("libpng_jll"),
    Dependency("PCRE_jll"),
    Dependency("SDL2_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
