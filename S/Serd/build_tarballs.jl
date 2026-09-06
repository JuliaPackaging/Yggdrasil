# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# Serd: a lightweight C library for RDF syntax (Turtle, NTriples, NQuads,
# TriG) (https://gitlab.com/drobilla/serd), ISC. The base of sord, sratom
# and lilv.
name = "Serd"
version = v"0.32.10"

sources = [
    ArchiveSource("https://download.drobilla.net/serd-$(version).tar.xz",
                  "b0e93b49e52f01a049475b7886ef140407115a32d3b1e5dc5f95141c88275d1c"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/serd-*
install_license COPYING
meson setup build --cross-file="${MESON_TARGET_TOOLCHAIN}" --buildtype=release \
    -Ddefault_library=shared \
    -Ddocs=disabled -Dman=disabled -Dtests=disabled -Dtools=enabled
meson compile -C build -j${nproc}
meson install -C build
"""

platforms = supported_platforms()

products = [
    LibraryProduct(["libserd-0", "libserd", "serd-0"], :libserd),   # on Windows BB parses libfoo-0.dll as "libfoo"
    ExecutableProduct("serdi", :serdi),
]

dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
