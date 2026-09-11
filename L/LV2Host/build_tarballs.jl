# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# The headless LV2 host from AudioPlugins.jl (https://github.com/SciML/AudioPlugins.jl):
# one C translation unit, `csrc/lv2_host.c`, exposing a C ABI of scalar doubles
# for hosting LV2 audio plugins. It is the LV2 counterpart of CLAPHost_jll.
#
# Unlike CLAP, LV2 describes a plugin's ports in Turtle manifests next to the
# binary rather than in the binary, so this needs a manifest reader: lilv, which
# brings serd, sord, sratom and zix. `lv2_jll` supplies both the LV2 headers
# (lilv-0.pc has `Requires: lv2`) and, at run time, the LV2 specification
# bundles under `lib/lv2` that lilv needs to classify ports.
name = "LV2Host"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/SciML/AudioPlugins.jl.git",
              "54f3cfd011edc33c71b702d888a2d6fab056e331"),  # v1.1.2 (registered)
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/AudioPlugins.jl
install_license LICENSE csrc/vendor/LV2-ISC-LICENSE

# On FreeBSD the meson-built JLLs (Lilv, Zix, Serd, lv2, Sord, ...) ship their
# pkg-config files in libdata/pkgconfig, which is not on the default search path.
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH:+${PKG_CONFIG_PATH}:}${prefix}/libdata/pkgconfig"

mkdir -p "${libdir}" "${includedir}"
# No -Icsrc/vendor here: the vendored LV2 headers are for a standalone build
# that has only lilv. `pkg-config --cflags lilv-0` pulls in lv2_jll's copy, and
# lilv.h and lv2_host.c must resolve <lv2/core/lv2.h> to the same one.
${CC} -std=gnu99 -O2 -fPIC -shared -Wall -Wextra \
    -o "${libdir}/liblv2_host.${dlext}" csrc/lv2_host.c \
    $(pkg-config --cflags --libs lilv-0) -lm
install -Dm644 csrc/lv2_host.h "${includedir}/lv2_host.h"
"""

# Lilv_jll 0.28.0 builds for every one of these 18 triplets, so there is
# nothing to filter out.
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("liblv2_host", :liblv2_host),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Lilv_jll"; compat="0.28.0"),
    Dependency("lv2_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10")
