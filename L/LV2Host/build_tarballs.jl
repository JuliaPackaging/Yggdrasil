# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# The headless LV2 host from AudioPlugins.jl (https://github.com/SciML/AudioPlugins.jl):
# one C translation unit, `csrc/lv2_host.c`, exposing a C ABI of scalar doubles
# for hosting LV2 audio plugins, with discovery through lilv. The companion of
# CLAPHost (C/CLAPHost); the version tracks the AudioPlugins.jl release whose
# `csrc/` is built.
#
# 1.1.1 rebuilds from a tree carrying SciML/AudioPlugins.jl#61, which lifted a
# fixed 256-entry descriptor cache in `lv2_host_scan`. An LV2 search path
# holding more plugins than that was reported as holding 256, silently, and
# indistinguishably from a path that really does: the LSP collection alone is
# 198 plugins, and a search path routinely adds the system directories on top.
# Patch rather than minor: the fix adds no exported symbol and changes no
# signature, so `lv2_host.h` and the ABI are identical to 1.1.0's.
name = "LV2Host"
version = v"1.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/SciML/AudioPlugins.jl.git",
              "f48574da93f3fac9f3d612c16b60657043320c35"),  # SciML/AudioPlugins.jl main
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/AudioPlugins.jl
install_license LICENSE csrc/vendor/LV2-ISC-LICENSE

mkdir -p "${libdir}" "${includedir}"
# The host includes <lv2/...> through the include path so that it and lilv.h
# resolve to the same copy; lilv's own headers come from Lilv_jll.
${CC} -std=gnu99 -O2 -fPIC -shared -Wall -Wextra \
    -Icsrc/vendor -I"${includedir}/lilv-0" -I"${includedir}" \
    -o "${libdir}/liblv2_host.${dlext}" csrc/lv2_host.c \
    -L"${libdir}" -llilv-0 -lm
install -Dm644 csrc/lv2_host.h "${includedir}/lv2_host.h"
"""

platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("liblv2_host", :liblv2_host),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Lilv_jll"; compat="0.28.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10")
