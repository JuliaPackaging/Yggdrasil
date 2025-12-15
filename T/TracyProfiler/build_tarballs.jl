# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TracyProfiler"
version = v"0.13.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/wolfpld/tracy.git",
              "05cceee0df3b8d7c6fa87e9638af311dbabc63cb"), # v0.13.1
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX11.0.sdk.tar.xz",
                  "d3feee3ef9c6016b526e1901013f264467bb927865a03422a9cb925991cc9783"),
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
    # i686 needs -Wa,-mbig-obj to handle large object files (PE/COFF section limit)
    if [[ "${target}" == i686-* ]]; then
        CMAKE_FLAGS+=(-DCMAKE_C_FLAGS="-Wa,-mbig-obj" -DCMAKE_CXX_FLAGS="-Wa,-mbig-obj")
        # Create Windows.h symlink for case-sensitive includes (usearch library uses <Windows.h>)
        ln -sf windows.h /opt/${target}/${target}/sys-root/include/Windows.h
    fi
    # Note: WINVER/_WIN32_WINNT are already defined by BinaryBuilder toolchain, don't redefine
elif [[ "${target}" == *-apple-darwin* ]]; then
    export MACOSX_DEPLOYMENT_TARGET=13.3
    # Disable LTO on macOS - Tracy enables it by default in Release mode, but it causes
    # CMAKE_C_COMPILER_AR-NOTFOUND errors in BinaryBuilder cross-compilation because
    # CPM-downloaded dependencies (zstd, tidy) don't respect the toolchain file properly.
    # The CMake flag alone isn't enough - CPM sub-projects ignore it. We need to:
    # 1. Disable ccache (Tracy wraps AR with ccache via RULE_LAUNCH, causing AR-NOTFOUND)
    # 2. Disable LTO via compiler flags (for CPM deps that ignore CMake settings)
    export CCACHE_DISABLE=1
    export CFLAGS="${CFLAGS} -fno-lto"
    export CXXFLAGS="${CXXFLAGS} -fno-lto"
    export LDFLAGS="${LDFLAGS} -fno-lto"
    CMAKE_FLAGS+=(
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF
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

# Install newer macOS SDK for x86_64 darwin
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    pushd $WORKSPACE/srcdir/MacOSX11.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    rm -rf /opt/${target}/${target}/sys-root/usr/include/libxml2/libxml
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd
fi

# Apply patch to skip ExternalProject for embed if pre-built binary exists
atomic_patch -p1 ../patches/cross-compile-embed.patch

# Apply patch to fix MSVC-specific /MP flag on MinGW
atomic_patch -p1 ../patches/mingw-no-msvc-flags.patch

# Apply patch to fix TracyPopcnt.hpp for MinGW (use GCC builtins instead of MSVC intrinsics)
atomic_patch -p1 ../patches/mingw-popcnt.patch

# Pre-build the 'embed' helper tool with the host compiler.
# This tool embeds fonts/manual/prompts into C++ source during the build.
# CMake's ExternalProject would build it for the target architecture, which fails
# during cross-compilation (can't run aarch64 binary on x86_64 host).
# The patch we applied makes CMake skip ExternalProject if embed already exists.
echo "Building embed helper for host..."
mkdir -p build/profiler
${CXX_BUILD:-c++} -std=c++20 -O2 \
    -I public/common \
    public/common/tracy_lz4.cpp \
    public/common/tracy_lz4hc.cpp \
    profiler/helpers/embed.cpp \
    -o build/profiler/embed

# Build profiler
cmake -S profiler -B build/profiler "${CMAKE_FLAGS[@]}"
cmake --build build/profiler --parallel ${nproc}
install -Dm755 build/profiler/tracy-profiler${exeext} ${bindir}/tracy${exeext}

# Build capture utility
cmake -S capture -B build/capture "${CMAKE_FLAGS[@]}"
cmake --build build/capture --parallel ${nproc}
install -Dm755 build/capture/tracy-capture${exeext} ${bindir}/tracy-capture${exeext}

# Build update utility
cmake -S update -B build/update "${CMAKE_FLAGS[@]}"
cmake --build build/update --parallel ${nproc}
install -Dm755 build/update/tracy-update${exeext} ${bindir}/tracy-update${exeext}

# Build csvexport utility
cmake -S csvexport -B build/csvexport "${CMAKE_FLAGS[@]}"
cmake --build build/csvexport --parallel ${nproc}
install -Dm755 build/csvexport/tracy-csvexport${exeext} ${bindir}/tracy-csvexport${exeext}

# Build import utilities
cmake -S import -B build/import "${CMAKE_FLAGS[@]}"
cmake --build build/import --parallel ${nproc}
install -Dm755 build/import/tracy-import-chrome${exeext} ${bindir}/tracy-import-chrome${exeext}

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
    ExecutableProduct("tracy-capture", :capture),
    ExecutableProduct("tracy-csvexport", :csvexport),
    ExecutableProduct("tracy-update", :update),
    ExecutableProduct("tracy-import-chrome", :import_chrome),
]

x11_platforms = filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms)

dependencies = [
    # Note: Tracy v0.13+ needs Capstone 6.x (AARCH64 naming), but Capstone_jll is 4.x
    # So we let Tracy download Capstone 6.x via CPM instead
    Dependency("FreeType2_jll"; compat="2.10.4"),
    Dependency("Dbus_jll"; platforms=filter(Sys.islinux, platforms)),
    Dependency("GLFW_jll"),
    # Tracy v0.13+ requires libcurl >= 7.87.0 for CURLOPT_CA_CACHE_TIMEOUT, CURL_WRITEFUNC_ERROR
    Dependency("LibCURL_jll"; compat="7.87,8"),
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"11")
