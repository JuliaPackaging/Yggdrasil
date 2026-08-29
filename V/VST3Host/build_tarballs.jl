# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# The headless VST3 host from AudioPlugins.jl (https://github.com/SciML/AudioPlugins.jl):
# one C++ translation unit, `csrc/vst3_host.cpp`, exposing an extern "C" ABI
# of scalar doubles for hosting VST3 audio plugins. Built against the SDK from
# vst3sdk_jll (a build dependency only: the SDK's static libraries are linked
# in, so the result is self-contained and exports only the C surface). The
# companion of CLAPHost and LV2Host; the version tracks the AudioPlugins.jl
# release whose `csrc/` is built.
name = "VST3Host"
version = v"1.3.0"

sources = [
    GitSource("https://github.com/SciML/AudioPlugins.jl.git",
              "14de157d7edb617e58d15d674b4cc23fcd4d0935"),  # SciML/AudioPlugins.jl PR "VST3 host: headless C++ shim" -- update to the merge commit if squashed
]

script = raw"""
cd ${WORKSPACE}/srcdir/AudioPlugins.jl
install_license LICENSE

SDK=${includedir}/vst3sdk
SDKLIB=${prefix}/lib/vst3sdk
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

${CXX} -std=c++17 -O2 -fPIC -shared -fvisibility=hidden -fvisibility-inlines-hidden \
    ${EXTRA_FLAGS:-} -DRELEASE=1 -I"${SDK}" \
    -o "${libdir}/libvst3_host.${dlext}" \
    csrc/vst3_host.cpp ${HOSTING}/plugprovider.cpp ${MODULE} \
    -L"${SDKLIB}" -lsdk_hosting -lsdk_common -lsdk -lbase -lpluginterfaces ${EXTRA_LIBS}
install -Dm644 csrc/vst3_host.h "${includedir}/vst3_host.h"
"""

platforms = filter(p -> Sys.islinux(p) || Sys.isapple(p) || Sys.iswindows(p), supported_platforms())
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libvst3_host", :libvst3_host),
]

dependencies = [
    BuildDependency("vst3sdk_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"9")
