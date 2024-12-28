# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "FLTK"
version = v"1.3.8"

# Collection of sources required to build FLTK
sources = [
    ArchiveSource("https://www.fltk.org/pub/fltk/$(version)/fltk-$(version)-source.tar.gz",
                  "f3c1102b07eb0e7a50538f9fc9037c18387165bc70d4b626e94ab725b9d4d1bf")
]

# Bash recipe for building across all platforms
script = raw"""
apk add fltk fltk-dev fltk-fluid # Host FLUID install required for cross-compilation
if [[ ${target} == x86_64-linux-musl* ]]; then
    # Remove host system libraries otherwise get "undefined reference to getrandom" error message on x86_64
    rm /usr/lib/libexpat*
    rm /lib/libuuid*
    rm /usr/lib/libfontconfig*
fi
cd ${WORKSPACE}/srcdir/fltk-*
mkdir build
cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DOPTION_BUILD_SHARED_LIBS=ON \
    -DOPTION_USE_SYSTEM_LIBJPEG=ON \
    -DOPTION_USE_SYSTEM_LIBPNG=ON \
    -DOPTION_USE_SYSTEM_ZLIB=ON \
    -DOPTION_USE_THREADS=ON
make -j${nproc}
make install
install_license ../COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> arch(p) != "armv6l", supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libfltk", :libfltk),
    LibraryProduct("libfltk_forms", :libfltk_forms),
    LibraryProduct("libfltk_gl", :libfltk_gl),
    LibraryProduct("libfltk_images", :libfltk_images)
]

# Some dependencies are needed only on Linux and FreeBSD
x11_platforms = filter(p ->Sys.islinux(p) || Sys.isfreebsd(p), platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"; platforms=x11_platforms),
    Dependency("Fontconfig_jll"),
    Dependency("FreeType2_jll"; compat="2.10.4"),
    Dependency("JpegTurbo_jll"),
    Dependency("Libglvnd_jll"; platforms=x11_platforms),
    Dependency("libpng_jll"),
    Dependency("Xorg_libX11_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXext_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXfixes_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXft_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXinerama_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXrender_jll"; platforms=x11_platforms),
    Dependency("Zlib_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"9")
