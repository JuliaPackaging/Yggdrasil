# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Pango"
version = v"1.50.3"

# Collection of sources required to build Pango
sources = [
    ArchiveSource("http://ftp.gnome.org/pub/GNOME/sources/pango/$(version.major).$(version.minor)/pango-$(version).tar.xz",
                  "4add05edf51c1fb375a1ccde7498914120e23cb280dd7395b1aeb441f1838a4c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pango-*/
pip3 install gi-docgen
mkdir build && cd build
meson --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    -Dintrospection=disabled \
    ..
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> arch(p) != "armv6l", supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct(["libpango", "libpango-1", "libpango-1.0"], :libpango),
    LibraryProduct(["libpangocairo", "libpangocairo-1", "libpangocairo-1.0"], :libpangocairo),
    LibraryProduct(["libpangoft2", "libpangoft2-1", "libpangoft2-1.0"], :libpangoft),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Cairo_jll"; compat="1.16.1"),
    Dependency("Fontconfig_jll"),
    Dependency("FreeType2_jll"),
    Dependency("FriBidi_jll"),
    Dependency("Glib_jll"; compat="2.68.1"),
    Dependency("HarfBuzz_jll"; compat="2.8.1"),
    BuildDependency("Xorg_xorgproto_jll"; platforms=filter(p->Sys.islinux(p)||Sys.isfreebsd(p), platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
