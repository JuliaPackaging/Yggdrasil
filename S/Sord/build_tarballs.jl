# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# Sord: a lightweight C library for storing RDF statements in memory
# (https://gitlab.com/drobilla/sord), ISC. Needed by sratom and lilv.
name = "Sord"
version = v"0.16.22"

sources = [
    ArchiveSource("https://download.drobilla.net/sord-$(version).tar.xz",
                  "bb23b34b216579136795d518cffa73d91cf205594ce9accebfd408afb839173f"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/sord-*
install_license COPYING
# On FreeBSD the meson-built JLLs (Zix, Serd, lv2, Sord, ...) ship their pkg-config
# files in libdata/pkgconfig, which is not on the default search path.
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH:+${PKG_CONFIG_PATH}:}${prefix}/libdata/pkgconfig"
meson setup build --cross-file="${MESON_TARGET_TOOLCHAIN}" --buildtype=release \
    -Ddefault_library=shared \
    -Dbindings_cpp=disabled -Ddocs=disabled -Dman=disabled -Dtests=disabled -Dtools=enabled
meson compile -C build -j${nproc}
meson install -C build
"""

platforms = supported_platforms()

products = [
    LibraryProduct(["libsord-0", "libsord", "sord-0"], :libsord),   # on Windows BB parses libfoo-0.dll as "libfoo"
    ExecutableProduct("sordi", :sordi),
]

dependencies = [
    Dependency("Zix_jll"; compat="0.8.2"),
    Dependency("Serd_jll"; compat="0.32.10"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
