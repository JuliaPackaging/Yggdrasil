# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# Lilv: the C library for hosting LV2 plugins -- discovery of installed
# bundles, plugin and port metadata, instantiation (https://gitlab.com/lv2/lilv),
# ISC. The `lv2ls` and `lv2info` tools are included; `lv2apply`, which needs
# libsndfile, is not (tools=auto builds it only when sndfile is found).
#
# `lv2_jll` is a runtime dependency, not only a build one: lilv needs the LV2
# specification bundles (`lib/lv2/*.lv2`) to classify plugins and ports, so a
# host should add `lv2_jll`'s `lib/lv2` to `LV2_PATH` alongside the user's
# plugin directories.
name = "Lilv"
version = v"0.28.0"

sources = [
    ArchiveSource("https://download.drobilla.net/lilv-$(version).tar.xz",
                  "8dcb70adb5cf072335115a6b091f4113710bdc73abaadaa3f9e9c1e55957b149"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/lilv-*
install_license COPYING
# On FreeBSD the meson-built JLLs (Zix, Serd, lv2, Sord, ...) ship their pkg-config
# files in libdata/pkgconfig, which is not on the default search path.
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH:+${PKG_CONFIG_PATH}:}${prefix}/libdata/pkgconfig"
meson setup build --cross-file="${MESON_TARGET_TOOLCHAIN}" --buildtype=release \
    -Ddefault_library=shared \
    -Dbindings_cpp=disabled -Dbindings_py=disabled -Ddocs=disabled \
    -Ddynmanifest=disabled -Dtests=disabled -Dtools=auto
meson compile -C build -j${nproc}
meson install -C build
"""

platforms = supported_platforms()

products = [
    LibraryProduct(["liblilv-0", "liblilv", "lilv-0"], :liblilv),   # on Windows BB parses libfoo-0.dll as "libfoo"
    ExecutableProduct("lv2ls", :lv2ls),
    ExecutableProduct("lv2info", :lv2info),
]

dependencies = [
    Dependency("Zix_jll"; compat="0.8.2"),
    Dependency("Serd_jll"; compat="0.32.10"),
    Dependency("Sord_jll"; compat="0.16.22"),
    Dependency("Sratom_jll"; compat="0.6.22"),
    Dependency("lv2_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
