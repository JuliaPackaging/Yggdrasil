# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

# The Steinberg VST 3 SDK (https://github.com/steinbergmedia/vst3sdk), MIT
# since version 3.8 (LICENSE.txt at the pinned tag is the MIT text; older
# tags carried a GPLv3 / proprietary dual licence and must not be used).
#
# What this ships, for hosts and for plugin authors alike:
#   * the headers: pluginterfaces/, base/, public.sdk/source/ (the SDK is
#     used as a source tree, so the tree is installed under include/vst3sdk
#     with the .cpp files that plugins and hosts compile directly -- the
#     per-platform module entry, vstsinglecomponenteffect.cpp,
#     hosting/plugprovider.cpp, hosting/module_<os>.cpp);
#   * the static libraries: base, pluginterfaces, sdk, sdk_common,
#     sdk_hosting (lib/vst3sdk/);
#   * two GUI-free example plugin bundles (lib/vst3/*.vst3):
#     `again-sample-accurate.vst3`, the SDK's gain example, and `adelay.vst3`,
#     so a host can be tested against a real plugin without a compiler.
# VSTGUI, the hosting examples and the validator are not built, and no
# moduleinfo.json is generated (moduleinfotool is built for the target and
# cannot run while cross-compiling; hosts do not need the file).
name = "vst3sdk"
version = v"3.8.1"

# The SDK repository is a shell around git submodules; each is pinned to the
# commit the v3.8.1_build_84 tag references.
sources = [
    GitSource("https://github.com/steinbergmedia/vst3sdk.git",
              "3cdf9ca5d1f5b1b21e0a86832aa4abe55607bd96"),   # v3.8.1_build_84
    GitSource("https://github.com/steinbergmedia/vst3_base.git",
              "fcf9da0bd27a16f7f03773a3a39822f28f5c8477"),
    GitSource("https://github.com/steinbergmedia/vst3_pluginterfaces.git",
              "4f547e8e102b47de4a8b8aaf343c73b700786372"),
    GitSource("https://github.com/steinbergmedia/vst3_public_sdk.git",
              "586dc5e6c8012c3e4b01c79389375cbe96bdb1da"),
    GitSource("https://github.com/steinbergmedia/vst3_cmake.git",
              "054c9143cbb8d47fc4694e473f2ee3b4d951a8f5"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/vst3sdk
# Put the submodules where the SDK's CMake expects them.
rmdir base pluginterfaces public.sdk cmake
mv ../vst3_base base
mv ../vst3_pluginterfaces pluginterfaces
mv ../vst3_public_sdk public.sdk
mv ../vst3_cmake cmake
# vstgui4, doc and tutorials stay empty: not built, not shipped.
mkdir -p vstgui4 doc tutorials

install_license LICENSE.txt

if [[ "${target}" == *-mingw* ]]; then
    # mingw's libstdc++ has no std::aligned_alloc either; the SDK's MSVC path
    # (_aligned_malloc / _aligned_free from <malloc.h>) works with mingw too.
    sed -i 's/defined(_MSC_VER)/defined(_WIN32)/g' public.sdk/source/vst/utility/alignedalloc.h
fi

# The SDK wants CMake >= 3.25: use the CMake_jll host build dependency
# rather than the rootfs's older one.
apk del cmake

# The SDK runs its platform detection (APPLE / WIN32 -> SMTG_MAC / SMTG_WIN)
# before project(), i.e. before the toolchain file is loaded, so a cross
# build is classified as the build host (Linux) unless told otherwise.
PLATFORM_FLAGS=()
if [[ "${target}" == *-apple-* ]]; then
    # xcodebuild is not available: give the SDK an Xcode version so it does
    # not abort; one architecture per build; no code signing.
    export XCODE_VERSION=15.0
    # The SDK's bundle post-build step calls codesign unconditionally; a
    # no-op codesign shim stands in for it (nothing is signed here anyway).
    mkdir -p ${WORKSPACE}/shim-bin
    printf '#!/bin/sh\nexit 0\n' > ${WORKSPACE}/shim-bin/codesign
    chmod +x ${WORKSPACE}/shim-bin/codesign
    export PATH="${WORKSPACE}/shim-bin:${PATH}"
    PLATFORM_FLAGS+=(-DAPPLE=ON -DXCODE_VERSION=15.0 -DSMTG_BUILD_UNIVERSAL_BINARY=OFF -DSMTG_DISABLE_CODE_SIGNING=ON)
elif [[ "${target}" == *-mingw* ]]; then
    # UNIX is true on the build host before project() and the SDK's macro
    # checks it before WIN32, so make the macro look at WIN32 first (the
    # file has CRLF line endings, hence the CR strip).
    sed -i 's/\r$//' cmake/modules/SMTG_DetectPlatform.cmake
    sed -i 's/^    if(APPLE)$/    if(WIN32)\n        set(SMTG_WIN TRUE CACHE INTERNAL ${SMTG_PLATFORM_DETECTION_COMMENT})\n    elseif(APPLE)/' \
        cmake/modules/SMTG_DetectPlatform.cmake
    PLATFORM_FLAGS+=(-DWIN32=ON)
fi

cmake -B build -G Ninja "${PLATFORM_FLAGS[@]}" \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DSMTG_ENABLE_VSTGUI_SUPPORT=OFF \
    -DSMTG_ENABLE_VST3_HOSTING_EXAMPLES=OFF \
    -DSMTG_ENABLE_VST3_PLUGIN_EXAMPLES=ON \
    -DSMTG_RUN_VST_VALIDATOR=OFF \
    -DSMTG_CREATE_PLUGIN_LINK=OFF \
    -DSMTG_CREATE_BUNDLE_FOR_WINDOWS=OFF \
    -DSMTG_CREATE_MODULE_INFO=OFF \
    -DSMTG_ENABLE_IOS_TARGETS=OFF
# The libraries, plus two GUI-free examples: the SDK's gain example (the
# sample-accurate variant) and a delay. The rest of the examples (mda-vst3
# and friends) are large and not needed by anyone hosting.
cmake --build build --parallel ${nproc} --target \
    base pluginterfaces sdk sdk_common sdk_hosting again-sample-accurate adelay

# The SDK's CMake (SMTG_ConfigureCmakeGenerator.cmake) drops the per-config
# subdirectory on Windows.
if [[ "${target}" == *-mingw* ]]; then
    BUILD_LIBDIR=build/lib
    BUILD_VST3DIR=build/VST3
else
    BUILD_LIBDIR=build/lib/Release
    BUILD_VST3DIR=build/VST3/Release
fi

# Static libraries.
mkdir -vp ${prefix}/lib/vst3sdk
cp -v ${BUILD_LIBDIR}/*.a ${prefix}/lib/vst3sdk/

# The source tree as headers + directly-compiled sources.
mkdir -vp ${includedir}/vst3sdk
cp -vr pluginterfaces base public.sdk ${includedir}/vst3sdk/
rm -rfv ${includedir}/vst3sdk/public.sdk/samples/vst/mda-vst3/*/media \
        ${includedir}/vst3sdk/public.sdk/samples/vst-hosting \
        ${includedir}/vst3sdk/base/build ${includedir}/vst3sdk/*/.git*
find ${includedir}/vst3sdk -type f \
    \( -name '*.png' -o -name '*.jpg' -o -name '*.uidesc' -o -name '*.rc' -o -name '.git*' \) \
    -print -delete

# Example plugin bundles (GUI-free), for hosting tests. Only the two built
# above: on macOS the SDK's CMake lays out a bundle skeleton for every
# plugin target at configure time.
mkdir -vp ${prefix}/lib/vst3
cp -vr ${BUILD_VST3DIR}/{again-sample-accurate,adelay}.vst3 ${prefix}/lib/vst3/
"""

# std::aligned_alloc, and std::filesystem in the hosting code, need a newer SDK
# than the rootfs default; both are available from macOS 10.15.
sources, script = require_macos_sdk("11.3", sources, script; deployment_target="10.15")

# The SDK targets Linux, macOS and Windows; nothing else.
platforms = filter(p -> Sys.islinux(p) || Sys.isapple(p) || Sys.iswindows(p), supported_platforms())
platforms = expand_cxxstring_abis(platforms)

products = [
    FileProduct("include/vst3sdk/pluginterfaces/base/funknown.h", :funknown_h),
    FileProduct("include/vst3sdk/public.sdk/source/vst/hosting/module.h", :hosting_module_h),
    FileProduct("lib/vst3sdk/libbase.a", :libbase_a),
    FileProduct("lib/vst3sdk/libpluginterfaces.a", :libpluginterfaces_a),
    FileProduct("lib/vst3sdk/libsdk.a", :libsdk_a),
    FileProduct("lib/vst3sdk/libsdk_common.a", :libsdk_common_a),
    FileProduct("lib/vst3sdk/libsdk_hosting.a", :libsdk_hosting_a),
    FileProduct("lib/vst3/again-sample-accurate.vst3", :again_sample_accurate_vst3),
]

dependencies = [
    HostBuildDependency(PackageSpec(; name="CMake_jll")),   # the SDK wants CMake >= 3.25
    # The example plugin bundles link libstdc++/libgcc_s.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# C++17 with std::filesystem in the hosting code: GCC 9 or newer.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"9")
