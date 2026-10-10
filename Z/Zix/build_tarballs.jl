# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# Zix: a lightweight C library of portability wrappers and data structures
# (https://gitlab.com/drobilla/zix), ISC. A dependency of sord and lilv.
name = "Zix"
version = v"0.8.2"

sources = [
    ArchiveSource("https://download.drobilla.net/zix-$(version).tar.xz",
                  "4c73aab0f8cbbfe56b00c8c6d648316021e699c5ae6cbf254391ef309047e67b"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/zix-*
install_license COPYING
meson setup build --cross-file="${MESON_TARGET_TOOLCHAIN}" --buildtype=release \
    -Ddefault_library=shared \
    -Dbenchmarks=disabled -Ddocs=disabled -Dtests=disabled -Dtests_cpp=disabled
meson compile -C build -j${nproc}
meson install -C build
"""

platforms = supported_platforms()

products = [
    LibraryProduct(["libzix-0", "libzix", "zix-0"], :libzix),   # on Windows BB parses libfoo-0.dll as "libfoo"
]

dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
