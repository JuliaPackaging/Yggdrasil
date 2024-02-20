# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libglvnd"
version = v"1.6.0"

# Collection of sources required to build Libglvnd
sources = [
    ArchiveSource("https://gitlab.freedesktop.org/glvnd/libglvnd/-/archive/v$(version)/libglvnd-v$(version).tar.gz",
                  "efc756ffd24b24059e1c53677a9d57b4b237b00a01c54a6f1611e1e51661d70c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libglvnd-*/
mkdir build && cd build
FLAGS=()
if [[ "${target}" == *musl* ]]; then
    FLAGS=(-Dtls=false)
fi
meson --cross-file="${MESON_TARGET_TOOLCHAIN}" --buildtype=release "${FLAGS[@]}" ..
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
