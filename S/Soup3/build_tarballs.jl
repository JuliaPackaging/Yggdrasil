using BinaryBuilder

name = "Soup3"
version = v"3.2.1"

# Collection of sources required to build Soup
sources = [
    ArchiveSource("https://download.gnome.org/sources/libsoup/$(version.major).$(version.minor)/libsoup-$(version).tar.xz",
        "b1eb3d2c3be49fbbd051a71f6532c9626bcecea69783190690cd7e4dfdf28f29"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libsoup-*/
install_license COPYING

mkdir build_glib && cd build_glib
meson --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    --buildtype=release \
    -Dtls_check=false \
    -Dtests=false \
    -Ddocs=disabled \
    -Dsysprof=disabled \
    ..

if [[ "${target}" != *darwin* ]]; then
    # https://github.com/rbgirshick/py-faster-rcnn/issues/706
    sed -i "s/-R/-Wl,-rpath=/" build.ninja
fi

if [[ "${target}" == *86*-linux-gnu* ]]; then
    # https://stackoverflow.com/questions/2418157/c-error-undefined-reference-to-clock-gettime-and-clock-settime
    sed -i 's/$ARGS -o $out $in $LINK_ARGS/$ARGS -o $out $in $LINK_ARGS -lrt/' build.ninja
fi

ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libsoup", "libsoup-3", "libsoup-3.0"], :libsoup),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Host gettext needed for "msgfmt"
    HostBuildDependency("Gettext_jll"),
    Dependency("Glib_jll"; compat="2.74.0"),
    Dependency("SQLite_jll"),
    Dependency("nghttp2_jll"),
    Dependency("brotli_jll"),
    Dependency("libpsl_jll"),
    Dependency("GlibNetworking_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
