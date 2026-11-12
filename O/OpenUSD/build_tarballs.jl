using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "OpenUSD"
tag = "v25.11"
version = VersionNumber(tag)

sources = [
    GitSource("https://github.com/PixarAnimationStudios/OpenUSD.git",
              "363a7c8da8d1937072a5f0989e91faf72eb1fa76";
              tag),
    DirectorySource("./bundled"),
]

script = raw"""
apk del cmake
cd ${WORKSPACE}/srcdir/OpenUSD
for p in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${p}
done
if [[ "${target}" == *-mingw* ]]; then
    # Upstream includes Windows SDK headers with MSVC's casing; MinGW's are lowercase
    mkdir -pv ${WORKSPACE}/srcdir/wininclude
    for h in Windows Shlwapi ShlwAPI DbgHelp Winsock2 WinIoCtl Psapi Memoryapi Shellapi; do
        echo "#include <${h,,}.h>" > ${WORKSPACE}/srcdir/wininclude/${h}.h
    done
    export CXXFLAGS="-I${WORKSPACE}/srcdir/wininclude"
    # Some classes export only a few members; GNU ld then leaves their vtables unexported
    export LDFLAGS="-Wl,--export-all-symbols"
fi
# OpenUSD computes RPATHs from a REALPATH'd origin, which breaks with the symlinked ${prefix};
# skip them and let the auditor set them
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_SKIP_INSTALL_RPATH=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DPXR_ENABLE_PYTHON_SUPPORT=OFF \
    -DPXR_ENABLE_GL_SUPPORT=OFF \
    -DPXR_BUILD_IMAGING=OFF \
    -DPXR_BUILD_USD_IMAGING=OFF \
    -DPXR_BUILD_USDVIEW=OFF \
    -DPXR_BUILD_EXEC=OFF \
    -DPXR_BUILD_TESTS=OFF \
    -DPXR_BUILD_EXAMPLES=OFF \
    -DPXR_BUILD_TUTORIALS=OFF \
    -DPXR_BUILD_USD_TOOLS=OFF \
    -DPXR_BUILD_DOCUMENTATION=OFF
cmake --build build --parallel ${nproc}
cmake --install build
install_license LICENSE.txt NOTICE.txt
"""

# The default SDK's libc++ lacks std::shared_ptr<T[]> and an unambiguous std::abs(int)
sources, script = require_macos_sdk("11.3", sources, script)

platforms = supported_platforms()
# pxr/base/arch supports only x86_64 and arm64 (64-bit check in CMakeLists.txt, #error in arch/defines.h)
filter!(p -> arch(p) in ("x86_64", "aarch64"), platforms)
# pxr/base/arch has no FreeBSD port
filter!(!Sys.isfreebsd, platforms)
# Intel Macs are not supported
filter!(p -> !(Sys.isapple(p) && arch(p) == "x86_64"), platforms)
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libusd_ar", :libusd_ar),
    LibraryProduct("libusd_arch", :libusd_arch),
    LibraryProduct("libusd_gf", :libusd_gf),
    LibraryProduct("libusd_js", :libusd_js),
    LibraryProduct("libusd_kind", :libusd_kind),
    LibraryProduct("libusd_pcp", :libusd_pcp),
    LibraryProduct("libusd_plug", :libusd_plug),
    LibraryProduct("libusd_sdf", :libusd_sdf),
    LibraryProduct("libusd_sdr", :libusd_sdr),
    LibraryProduct("libusd_tf", :libusd_tf),
    LibraryProduct("libusd_trace", :libusd_trace),
    LibraryProduct("libusd_usd", :libusd_usd),
    LibraryProduct("libusd_usdGeom", :libusd_usdGeom),
    LibraryProduct("libusd_usdLux", :libusd_usdLux),
    LibraryProduct("libusd_usdShade", :libusd_usdShade),
    LibraryProduct("libusd_usdUtils", :libusd_usdUtils),
    LibraryProduct("libusd_usdVol", :libusd_usdVol),
    LibraryProduct("libusd_vt", :libusd_vt),
    LibraryProduct("libusd_work", :libusd_work),
]

dependencies = [
    HostBuildDependency("CMake_jll"),
    Dependency("oneTBB_jll"; compat="2022.0.0"),
]

# GCC 11 is the compiler Pixar tests OpenUSD with (VERSIONS.md)
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"11")
