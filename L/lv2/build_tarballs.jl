# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# The LV2 audio plugin specification (https://lv2plug.in): C headers plus the
# Turtle bundles that define the core ontology, ISC. Needed to build sratom
# and lilv, and at run time by lilv to describe plugin classes and ports.
# Example plugins are not built.
name = "lv2"
version = v"1.18.10"

sources = [
    ArchiveSource("https://lv2plug.in/spec/lv2-$(version).tar.xz",
                  "78c51bcf21b54e58bb6329accbb4dae03b2ed79b520f9a01e734bd9de530953f"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/lv2-*
install_license COPYING
meson setup build --cross-file="${MESON_TARGET_TOOLCHAIN}" --buildtype=release \
    -Ddocs=disabled -Dplugins=disabled -Dtests=disabled -Dold_headers=true \
    -Dlv2dir="${prefix}/lib/lv2"
meson compile -C build -j${nproc}
meson install -C build
"""

platforms = supported_platforms()

products = [
    FileProduct("include/lv2/core/lv2.h", :lv2_h),
    FileProduct("lib/lv2/core.lv2/manifest.ttl", :lv2_core_manifest),
]

dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
