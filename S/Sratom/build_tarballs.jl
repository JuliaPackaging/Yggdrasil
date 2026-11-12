# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# Sratom: a C library for serialising LV2 atoms to and from RDF
# (https://gitlab.com/lv2/sratom), ISC. Needed by lilv.
name = "Sratom"
version = v"0.6.22"

sources = [
    ArchiveSource("https://download.drobilla.net/sratom-$(version).tar.xz",
                  "0209b7d0f22c96abb416722ed735b0933be47931ecff4aa4b26ded7760b4f252"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/sratom-*
install_license COPYING
# On FreeBSD the meson-built JLLs (Zix, Serd, lv2, Sord, ...) ship their pkg-config
# files in libdata/pkgconfig, which is not on the default search path.
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH:+${PKG_CONFIG_PATH}:}${prefix}/libdata/pkgconfig"
meson setup build --cross-file="${MESON_TARGET_TOOLCHAIN}" --buildtype=release \
    -Ddefault_library=shared \
    -Ddocs=disabled -Dtests=disabled
meson compile -C build -j${nproc}
meson install -C build
"""

platforms = supported_platforms()

products = [
    LibraryProduct(["libsratom-0", "libsratom", "sratom-0"], :libsratom),   # on Windows BB parses libfoo-0.dll as "libfoo"
]

dependencies = [
    Dependency("Serd_jll"; compat="0.32.10"),
    Dependency("Sord_jll"; compat="0.16.22"),
    BuildDependency("lv2_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
