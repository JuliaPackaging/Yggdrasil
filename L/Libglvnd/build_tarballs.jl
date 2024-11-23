# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libglvnd"
version = v"1.7.0"

# Collection of sources required to build Libglvnd
sources = [
    ArchiveSource("https://gitlab.freedesktop.org/glvnd/libglvnd/-/archive/v$(version)/libglvnd-v$(version).tar.gz",
                  "2b6e15b06aafb4c0b6e2348124808cbd9b291c647299eaaba2e3202f51ff2f3d"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libglvnd-*/

if [[ "${target}" == *freebsd* ]]; then
    sysprefix=/usr/local
else
    sysprefix=/usr
fi

mkdir build && cd build
FLAGS=()
if [[ "${target}" == *musl* ]]; then
    FLAGS=(-Dtls=false)
fi
meson setup . .. \
    --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    --buildtype=release \
    --prefix=$sysprefix \
    --libdir=$prefix/lib \
    --includedir=$prefix/include \
    "${FLAGS[@]}"
ninja -j${nproc}
ninja install
# The license is embedded in the README file
install_license ../README.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p ->Sys.islinux(p) || Sys.isfreebsd(p), supported_platforms())
# Remove when X11 stack will support armv6l
filter!(p -> arch(p) != "armv6l", platforms)

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libEGL", :libEGL),
    LibraryProduct("libGLdispatch", :libGLdispatch),
    LibraryProduct("libGLESv1_CM", :libGLESv1_CM),
    LibraryProduct("libGLESv2", :libGLESv2),
    LibraryProduct("libGL", :libGL),
    LibraryProduct("libGLX", :libGLX),
    LibraryProduct("libOpenGL", :libOpenGL),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Xorg_libX11_jll"),
    Dependency("Xorg_libXext_jll"),
    BuildDependency("Xorg_xorgproto_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
