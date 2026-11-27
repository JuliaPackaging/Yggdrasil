# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

include("../../platforms/macos_sdks.jl")

# The headless LV2 host from AudioPlugins.jl (https://github.com/SciML/AudioPlugins.jl):
# one C translation unit, `csrc/lv2_host.c`, exposing a C ABI of scalar doubles
# for hosting LV2 audio plugins, with discovery through lilv. The companion of
# CLAPHost (C/CLAPHost).
name = "LV2Host"
version = v"1.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/SciML/AudioPlugins.jl.git",
              "db936e2e3f2e855a20944c19ff7adac21c176037"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/AudioPlugins.jl
install_license LICENSE csrc/vendor/LV2-ISC-LICENSE csrc/vendor/CLAP-LICENSE csrc/vendor/miniaudio.LICENSE

LIVE_LIBS="-pthread -lm"
if [[ "${target}" == *-mingw* ]]; then
    LIVE_LIBS="${LIVE_LIBS} -lavrt -lole32 -luuid -luser32 -lwinmm"
elif [[ "${target}" == *-apple-* ]]; then
    # __builtin_available needs ___isPlatformVersionAtLeast from compiler-rt
    LIVE_LIBS="${LIVE_LIBS} -framework CoreFoundation -framework CoreAudio -framework AudioToolbox -L${libdir}/darwin -lclang_rt.osx"
else
    LIVE_LIBS="${LIVE_LIBS} -ldl"
fi

mkdir -p "${libdir}" "${includedir}"
# The host includes <lv2/...> through the include path so that it and lilv.h
# resolve to the same copy; lilv's own headers come from Lilv_jll.
${CC} -std=gnu11 -DAP_LIVE_WITH_DEVICE -O2 -fPIC -shared -Wall -Wextra \
    -Icsrc/vendor -I"${includedir}/lilv-0" -I"${includedir}" \
    -o "${libdir}/liblv2_host.${dlext}" csrc/lv2_host.c csrc/lv2_live.c csrc/clap_live.c csrc/live_device.c \
    -L"${libdir}" -llilv-0 ${LIVE_LIBS}
install -Dm644 csrc/lv2_host.h "${includedir}/lv2_host.h"
install -Dm644 csrc/clap_live.h "${includedir}/clap_live.h"
install -Dm644 csrc/live_device.h "${includedir}/live_device.h"
"""

sources, script = require_macos_sdk("11.3", sources, script; deployment_target="10.15")

platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("liblv2_host", :liblv2_host),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Lilv_jll"; compat="0.28.0"),
    BuildDependency("LLVMCompilerRT_jll"; platforms = filter(Sys.isapple, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"9")
