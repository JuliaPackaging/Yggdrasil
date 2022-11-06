# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "SDL2"
version = v"2.24.2"

# Collection of sources required to build SDL2
sources = [
    GitSource("https://github.com/libsdl-org/SDL.git",
              "55b03c7493a7abed33cf803d1380a40fa8af903f"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SDL*/
# https://github.com/libsdl-org/SDL/issues/6491
atomic_patch -p1 ../patches/aarch64-darwin-remove-version-check.patch
mkdir build && cd build
FLAGS=()
if [[ "${target}" == *-linux-* ]] || [[ "${target}" == *-freebsd* ]]; then
    FLAGS+=(--with-x)
fi
../configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --enable-shared \
    --disable-static \
    "${FLAGS[@]}"
make -j${nproc}
make install
install_license ../LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libSDL2", "SDL2"], :libsdl2)
]

x11_platforms = filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"; platforms=x11_platforms),
    Dependency("Xorg_libX11_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXcursor_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXext_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXinerama_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXrandr_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXScrnSaver_jll"; platforms=x11_platforms),
    Dependency("Libglvnd_jll"; platforms=x11_platforms),
    Dependency("alsa_jll"; platforms=filter(Sys.islinux, platforms)),
    Dependency("alsa_plugins_jll"; platforms=filter(Sys.islinux, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
