# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

# The headless VST3 host from AudioPlugins.jl (https://github.com/SciML/AudioPlugins.jl):
# one C++ translation unit, `csrc/vst3_host.cpp`, exposing an extern "C" ABI
# of scalar doubles for hosting VST3 audio plugins. Built against the SDK from
# vst3sdk_jll (a build dependency only: the SDK's static libraries are linked
# in, so the result is self-contained and exports only the C surface). The
# companion of CLAPHost and LV2Host; the version tracks the AudioPlugins.jl
# release whose `csrc/` is built.
#
# 1.3.0 is a minor bump: it adds the live-session ABI (`ap_live_*` symbols,
# `csrc/clap_live.h` and `csrc/live_device.h`) alongside `vst3_host.h`; the
# existing `vst3_host_*` ABI is unchanged.
name = "VST3Host"
version = v"1.3.0"

sources = [
    GitSource("https://github.com/SciML/AudioPlugins.jl.git",
              "c7a6aee21c0fe6673ffb92df3a8599f9ee99648c"),  # SciML/AudioPlugins.jl main (PR 89, native live sessions)
]

script = raw"""
cd ${WORKSPACE}/srcdir/AudioPlugins.jl
install_license LICENSE csrc/vendor/CLAP-LICENSE csrc/vendor/miniaudio.LICENSE

SDK=${includedir}/vst3sdk
SDKLIB=${prefix}/lib/vst3sdk
LIVE_LIBS="-pthread -lm"
if [[ "${target}" == *-mingw* ]]; then
    LIVE_LIBS="${LIVE_LIBS} -lavrt -lole32 -luuid -luser32 -lwinmm"
elif [[ "${target}" == *-apple-* ]]; then
    LIVE_LIBS="${LIVE_LIBS} -framework CoreFoundation -framework CoreAudio -framework AudioToolbox"
else
    LIVE_LIBS="${LIVE_LIBS} -ldl"
fi

mkdir -p "${libdir}"

HOSTING=${SDK}/public.sdk/source/vst/hosting
if [[ "${target}" == *-mingw* ]]; then
    MODULE=${HOSTING}/module_win32.cpp
    EXTRA_LIBS="-lole32 -lshlwapi -lshell32 -luuid"   # module_win32.cpp: COM, PathRemoveFileSpec, SHGetKnownFolderPath + FOLDERID_* GUIDs
elif [[ "${target}" == *-apple-* ]]; then
    MODULE=${HOSTING}/module_mac.mm
    EXTRA_FLAGS="-fobjc-arc"     # module_mac.mm insists on ARC
    EXTRA_LIBS="-framework CoreFoundation -framework Foundation"
else
    MODULE=${HOSTING}/module_linux.cpp
    EXTRA_LIBS="-ldl -lpthread"
fi

${CC} -std=gnu11 -O2 -fPIC -fvisibility=hidden -DAP_LIVE_WITH_DEVICE \
    -c csrc/clap_live.c -o clap_live.o
${CC} -std=gnu11 -O2 -fPIC -fvisibility=hidden -DAP_LIVE_WITH_DEVICE \
    -c csrc/live_device.c -o live_device.o
${CXX} -std=c++17 -O2 -fPIC -shared -fvisibility=hidden -fvisibility-inlines-hidden \
    ${EXTRA_FLAGS:-} -DRELEASE=1 -I"${SDK}" \
    -o "${libdir}/libvst3_host.${dlext}" \
    csrc/vst3_host.cpp csrc/vst3_live.cpp clap_live.o live_device.o ${HOSTING}/plugprovider.cpp ${MODULE} \
    -L"${SDKLIB}" -lsdk_hosting -lsdk_common -lsdk -lbase -lpluginterfaces ${EXTRA_LIBS} ${LIVE_LIBS}
install -Dm644 csrc/vst3_host.h "${includedir}/vst3_host.h"
install -Dm644 csrc/clap_live.h "${includedir}/clap_live.h"
install -Dm644 csrc/live_device.h "${includedir}/live_device.h"
"""

# Same SDK and deployment target as vst3sdk: the hosting sources use
# std::filesystem, and -fobjc-arc below 10.11 would need libarclite, which
# current SDKs no longer ship.
sources, script = require_macos_sdk("11.3", sources, script; deployment_target="10.15")

platforms = filter(p -> Sys.islinux(p) || Sys.isapple(p) || Sys.iswindows(p), supported_platforms())
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libvst3_host", :libvst3_host),
]

dependencies = [
    BuildDependency("vst3sdk_jll"),
    # The host links libstdc++ and libgcc_s.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"9")
