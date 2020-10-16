# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libglvnd"
version = v"1.3.0"

# Collection of sources required to build Libglvnd
sources = [
    ArchiveSource("https://gitlab.freedesktop.org/glvnd/libglvnd/uploads/d164b4e6bed74290f4d60e9a5b9bc31c/libglvnd-$(version).tar.gz",
                  "0f43bd9f6c20e6a75ff8cd57736bd78071da7a68e078ed39c81bcc710af30dc7"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libglvnd-*/
export CPPFLAGS="-I${includedir}"
FLAGS=()
if [[ "${target}" == *musl* ]]; then
    FLAGS=(--disable-tls)
fi
./configure --prefix=${prefix} --host=${target} "${FLAGS[@]}"
make -j${nproc}
make install
# The license is embedded in the README file
install_license README.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p ->Sys.islinux(p) || Sys.isfreebsd(p), supported_platforms())

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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

