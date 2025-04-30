# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TracyProfiler"
version = v"0.11.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/wolfpld/tracy.git",
              "5d542dc09f3d9378d005092a4ad446bd405f819a"), # v0.11.1
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX11.0.sdk.tar.xz",
                  "d3feee3ef9c6016b526e1901013f264467bb927865a03422a9cb925991cc9783"),
    DirectorySource("./bundled"),
]

script = raw"""
mkdir -vp $bindir

cd $WORKSPACE/srcdir/tracy*/

export TRACY_NO_ISA_EXTENSIONS=1
export DEFINES="-D__STDC_FORMAT_MACROS -DNO_PARALLEL_SORT"
if [[ "${target}" == *-mingw* ]]; then
    export TRACY_NO_LTO=1
    export DEFINES="-DWINVER=0x0601 -D_WIN32_WINNT=0x0601 -DNO_PARALLEL_SORT"
    atomic_patch -p1 ../patches/TracyProfiler-mingw32-win.patch
elif [[ "${target}" == *-apple-darwin* ]]; then
    export TRACY_NO_LTO=1
    export MACOSX_DEPLOYMENT_TARGET=11.0
fi

if [[ "${target}" == x86_64-apple-darwin* ]]; then
    echo "Installing newer MacOS 11.0 SDK"

    pushd $WORKSPACE/srcdir/MacOSX11.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    rm -rf /opt/${target}/${target}/sys-root/usr/include/libxml2/libxml
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd
fi

# Build / install the profiler GUI
cmake -B profiler/build -S profiler \
    -DLEGACY=1 \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DCMAKE_BUILD_TYPE=Release
cmake --build profiler/build --config Release --parallel ${nproc}
cp -v ./profiler/build/tracy* $bindir

# Build / install the update utility
cmake -B update/build -S update -DCMAKE_BUILD_TYPE=Release
cmake --build update/build --config Release --parallel
cp -v ./update/build/tracy* $bindir

# Build / install the capture utility
cmake -B capture/build -S capture -DCMAKE_BUILD_TYPE=Release
cmake --build capture/build --config Release --parallel
cp -v ./capture/build/tracy* $bindir

# Build / install the csvexport utility
cmake -B csvexport/build -S csvexport -DCMAKE_BUILD_TYPE=Release
cmake --build csvexport/build --config Release --parallel
cp -v ./csvexport/build/tracy* $bindir

# Build / install the import-chrome utility
cmake -B import-chrome/build -S import-chrome -DCMAKE_BUILD_TYPE=Release
cmake --build import-chrome/build --config Release --parallel
cp -v ./import-chrome/build/tracy* $bindir

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

x11_platforms = filter(p ->Sys.islinux(p) || Sys.isfreebsd(p), platforms)

dependencies = [
    Dependency("Capstone_jll"),
    Dependency("FreeType2_jll"; compat="2.10.4"),
    Dependency("Dbus_jll", platforms=filter(Sys.islinux, platforms)),
    Dependency("GLFW_jll"),
    # Needed for `pkg-config glfw3`
    BuildDependency("Xorg_xproto_jll", platforms=x11_platforms),
    BuildDependency("Xorg_kbproto_jll", platforms=x11_platforms),
]

# requires std-c++17, full support in gcc 7+, clang 8+
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8")
