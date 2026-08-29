# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# The headless LV2 host from AudioPlugins.jl (https://github.com/SciML/AudioPlugins.jl):
# one C translation unit, `csrc/lv2_host.c`, exposing a C ABI of scalar doubles
# for hosting LV2 audio plugins, with discovery through lilv. The companion of
# CLAPHost (C/CLAPHost); the version tracks the AudioPlugins.jl release whose
# `csrc/` is built.
name = "LV2Host"
version = v"1.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/SciML/AudioPlugins.jl.git",
              "c3239f3c339ba80c56b15e9a720d10e17518abfd"),  # SciML/AudioPlugins.jl PR "LV2 host: discovery through lilv" -- update to the merge commit if squashed
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
