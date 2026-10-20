# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

include("../../platforms/macos_sdks.jl")

name = "TracyProfiler"
version = v"0.13.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/wolfpld/tracy.git",
              "6cd7751479d4efd5c35f39e856891570a89dd060"), # v0.13.1 plus necessary patches
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir/tracy*/

# Use CMake >= 3.25 from CMake_jll instead of system cmake
apk del cmake

# Common CMake flags
CMAKE_FLAGS=(
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DNO_ISA_EXTENSIONS=ON
    -DLEGACY=ON
    -DTRACY_PATCHABLE_NOPSLEDS=ON
    -DDOWNLOAD_LIBCURL=OFF
    # Explicitly tell CMake where libcurl is - pkg-config often fails to find JLLs in cross-compilation.
    # These cache vars are checked by Tracy's vendor.cmake before pkg_check_modules runs.
    -DLIBCURL_FOUND=TRUE
    -DLIBCURL_INCLUDE_DIRS=${includedir}
    -DLIBCURL_LINK_LIBRARIES=${libdir}/libcurl.${dlext}
)

# Platform-specific settings
if [[ "${target}" == *-mingw* ]]; then
    # Create Windows.h symlink for case-sensitive includes (usearch library uses <Windows.h>)
    ln -sf windows.h /opt/${target}/${target}/sys-root/include/Windows.h
    # -Wa,-mbig-obj needed for large object files (PE/COFF section limit) - Tracy has huge template-heavy files
    export CFLAGS="${CFLAGS} -Wa,-mbig-obj"
    export CXXFLAGS="${CXXFLAGS} -Wa,-mbig-obj"
    # Disable LTO on MinGW - causes "plugin needed to handle lto object" errors
    export CFLAGS="${CFLAGS} -fno-lto"
    export CXXFLAGS="${CXXFLAGS} -fno-lto"
    export LDFLAGS="${LDFLAGS} -fno-lto"
    CMAKE_FLAGS+=(
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE=OFF
        # Link against Windows libraries - must use CMAKE_CXX_STANDARD_LIBRARIES
        # which gets appended at the END of the link line (GCC linker order matters)
        # - ws2_32: Winsock2 for socket functions
        # - ole32: COM functions (CoInitializeEx, CoCreateInstance, etc.) for NFD
        # - uuid: COM GUIDs (CLSID_FileOpenDialog, IID_IFileSaveDialog, etc.) for NFD
        # - dbghelp: Debug symbol functions (SymInitialize, SymFromAddr, etc.) for tracy-update
        "-DCMAKE_CXX_STANDARD_LIBRARIES=-lws2_32 -lole32 -luuid -ldbghelp"
        "-DCMAKE_C_STANDARD_LIBRARIES=-lws2_32 -lole32 -luuid -ldbghelp"
    )
    # Note: WINVER/_WIN32_WINNT are already defined by BinaryBuilder toolchain, don't redefine
elif [[ "${target}" == *-apple-darwin* ]]; then
    # Disable LTO on macOS - Tracy enables it by default in Release mode, but it causes
    # CMAKE_C_COMPILER_AR-NOTFOUND errors in BinaryBuilder cross-compilation because
    # CPM-downloaded dependencies (zstd, tidy, pugixml) don't respect the toolchain file.
    # We need to:
    # 1. Explicitly set AR/RANLIB paths (toolchain doesn't set these for cross-compilation)
    # 2. Disable LTO at all levels (CMake flags + compiler flags for CPM deps)
    export CFLAGS="${CFLAGS} -fno-lto"
    export CXXFLAGS="${CXXFLAGS} -fno-lto"
    export LDFLAGS="${LDFLAGS} -fno-lto"
    CMAKE_FLAGS+=(
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE=OFF
        -DCMAKE_C_COMPILER_AR=/opt/${target}/bin/${target}-ar
        -DCMAKE_CXX_COMPILER_AR=/opt/${target}/bin/${target}-ar
        -DCMAKE_C_COMPILER_RANLIB=/opt/${target}/bin/${target}-ranlib
        -DCMAKE_CXX_COMPILER_RANLIB=/opt/${target}/bin/${target}-ranlib
    )
elif [[ "${target}" == *-linux-* ]] || [[ "${target}" == *-freebsd* ]]; then
    # Help CMake find X11 in BinaryBuilder environment
    CMAKE_FLAGS+=(
        -DX11_X11_INCLUDE_PATH=${includedir}
        -DX11_X11_LIB=${libdir}/libX11.${dlext}
    )
    # Disable Wayland in GLFW when built from source (via CPM).
    # wayland-scanner is a host tool not available in cross-compilation.
    # This is needed because pkg-config often can't find GLFW_jll, causing CPM
    # to download and build GLFW from source.
    CMAKE_FLAGS+=(-DGLFW_BUILD_WAYLAND=OFF)
    # Add X11 include path and __STDC_FORMAT_MACROS for PRIu64 etc.
    export CXXFLAGS="-I${includedir} -D__STDC_FORMAT_MACROS ${CXXFLAGS}"
    export CFLAGS="-I${includedir} -D__STDC_FORMAT_MACROS ${CFLAGS}"
    # Link against libdl for dlclose/dlopen on glibc
    export LDFLAGS="-ldl ${LDFLAGS}"
fi

# Apply patch to skip ExternalProject for embed if pre-built binary exists
atomic_patch -p1 ../patches/cross-compile-embed.patch

# Pre-build the 'embed' helper tool with the host compiler.
# This tool embeds fonts/manual/prompts into C++ source during the build.
# CMake's ExternalProject would build it for the target architecture, which fails
# during cross-compilation (can't run aarch64 binary on x86_64 host).
# The patch we applied makes CMake skip ExternalProject if embed already exists.
echo "Building embed helper for host..."
mkdir -p build/profiler
${CXX_BUILD} -std=c++20 -O2 \
    -I public/common \
    public/common/tracy_lz4.cpp \
    public/common/tracy_lz4hc.cpp \
    profiler/helpers/embed.cpp \
    -o build/profiler/embed

# Build profiler
cmake -S profiler -B build/profiler "${CMAKE_FLAGS[@]}"
cmake --build build/profiler --parallel ${nproc}
# NOTE — the divergence in naming (`tracy`, not `tracy-profiler`) is necessary for Tracy.jl et al.
install -Dvm755 build/profiler/tracy-profiler${exeext} ${bindir}/tracy${exeext}

# Build capture utility
cmake -S capture -B build/capture "${CMAKE_FLAGS[@]}"
cmake --build build/capture --parallel ${nproc}
install -Dvm755 build/capture/tracy-capture${exeext} ${bindir}/tracy-capture${exeext}

# Build update utility
cmake -S update -B build/update "${CMAKE_FLAGS[@]}"
cmake --build build/update --parallel ${nproc}
install -Dvm755 build/update/tracy-update${exeext} ${bindir}/tracy-update${exeext}

# Build csvexport utility
cmake -S csvexport -B build/csvexport "${CMAKE_FLAGS[@]}"
cmake --build build/csvexport --parallel ${nproc}
install -Dvm755 build/csvexport/tracy-csvexport${exeext} ${bindir}/tracy-csvexport${exeext}

# Build import-chrome utility
cmake -S import -B build/import "${CMAKE_FLAGS[@]}"
cmake --build build/import --parallel ${nproc}
install -Dvm755 build/import/tracy-import-chrome${exeext} ${bindir}/tracy-import-chrome${exeext}

# Build import-fuchsia utility
cmake -S import -B build/import "${CMAKE_FLAGS[@]}"
cmake --build build/import --parallel ${nproc}
install -Dvm755 build/import/tracy-import-fuchsia${exeext} ${bindir}/tracy-import-fuchsia${exeext}

install_license LICENSE
"""

platforms = expand_cxxstring_abis(supported_platforms(; exclude=[
    Platform("armv6l", "linux"),
    Platform("armv6l", "linux"; libc=:musl),
    Platform("armv7l", "linux"),
    Platform("armv7l", "linux"; libc=:musl),
    # FreeBSD excluded: NFD (Native File Dialog) misdetects FreeBSD as Linux
    # and tries to use D-Bus, which isn't available on FreeBSD
    Platform("x86_64", "freebsd"),
    Platform("aarch64", "freebsd"),
]))

products = [
    ExecutableProduct("tracy", :tracy),
    ExecutableProduct("tracy-capture", :tracy_capture),
    ExecutableProduct("tracy-csvexport", :tracy_csvexport),
    ExecutableProduct("tracy-import-chrome", :tracy_import_chrome),
    ExecutableProduct("tracy-import-fuchsia", :tracy_import_fuchsia),
    ExecutableProduct("tracy-update", :tracy_update),
]

x11_platforms = filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms)

dependencies = [
    # Note: Tracy v0.13+ needs Capstone 6.x (AARCH64 naming), but Capstone_jll is 4.x
    # So we let Tracy download Capstone 6.x via CPM instead
    Dependency("FreeType2_jll"; compat="2.10.4"),
    Dependency("Dbus_jll"; platforms=filter(Sys.islinux, platforms)),
    Dependency("GLFW_jll"),
    # Tracy v0.13+ requires libcurl >= 7.87.0 for CURLOPT_CA_CACHE_TIMEOUT, CURL_WRITEFUNC_ERROR
    Dependency("LibCURL_jll"; compat="7.88.1,8"),
    # X11 dependencies for GLFW on Linux (needed for imgui_impl_glfw.cpp)
    Dependency("Xorg_libX11_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXrandr_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXinerama_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXcursor_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXi_jll"; platforms=x11_platforms),
    # X11 protocol headers (provides X11/Xatom.h, etc.)
    BuildDependency("Xorg_xorgproto_jll"; platforms=x11_platforms),
    # Tracy v0.13+ requires CMake 3.25+
    HostBuildDependency(PackageSpec(; name="CMake_jll")),
]

# Tracy v0.13+ requires C++20 with <latch> support, which needs GCC 11+
sources, script = require_macos_sdk("14.0", sources, script; deployment_target="14.0")
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"11")
