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
]

script = raw"""
cd $WORKSPACE/srcdir/tracy*/

# Common CMake flags
CMAKE_FLAGS=(
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DNO_ISA_EXTENSIONS=ON
    -DLEGACY=ON
    -DTRACY_PATCHABLE_NOPSLEDS=ON
    -DDOWNLOAD_CAPSTONE=OFF
)

# Platform-specific settings
if [[ "${target}" == *-mingw* ]]; then
    # Windows-specific flags
    CMAKE_FLAGS+=(-DCMAKE_CXX_FLAGS="-DWINVER=0x0601 -D_WIN32_WINNT=0x0601")
elif [[ "${target}" == *-apple-darwin* ]]; then
    export MACOSX_DEPLOYMENT_TARGET=13.3
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
    Platform("x86_64", "freebsd"),
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
    Dependency("Capstone_jll"),
    Dependency("FreeType2_jll"; compat="2.10.4"),
    Dependency("Dbus_jll"; platforms=filter(Sys.islinux, platforms)),
    Dependency("GLFW_jll"),
    # Needed for `pkg-config glfw3`
    Dependency("Xorg_xproto_jll"; platforms=x11_platforms),
    Dependency("Xorg_kbproto_jll"; platforms=x11_platforms),
    # Tracy v0.13+ requires CMake 3.25+
    HostBuildDependency(PackageSpec(; name="CMake_jll")),
]

# Tracy v0.13+ requires C++20, which needs GCC 10+
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"10")
