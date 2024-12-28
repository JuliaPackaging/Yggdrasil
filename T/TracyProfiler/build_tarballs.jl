# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TracyProfiler"
version = v"0.9.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/wolfpld/tracy.git",
              "897aec5b062664d2485f4f9a213715d2e527e0ca"), # v0.9.1
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

atomic_patch -p1 ../patches/TracyProfiler-nfd-extended-1.0.2.patch
atomic_patch -p1 ../patches/TracyProfiler-filter-user-text.patch
atomic_patch -p1 ../patches/TracyProfiler-no-divide-zero.patch
atomic_patch -p1 ../patches/TracyProfiler-rr-nopl-seq.patch

# Build / install the profiler GUI
make -e -j${nproc} -C profiler/build/unix LEGACY=1 IMAGE=tracy release
cp -v ./profiler/build/unix/tracy* $bindir

# Build / install the update utility
make -e -j${nproc} -C update/build/unix IMAGE=tracy-update release
cp -v ./update/build/unix/tracy* $bindir

# Build / install the capture utility
make -e -j${nproc} -C capture/build/unix IMAGE=tracy-capture release
cp -v ./capture/build/unix/tracy* $bindir

# Build / install the csvexport utility
make -e -j${nproc} -C csvexport/build/unix IMAGE=tracy-csvexport release
cp -v ./csvexport/build/unix/tracy* $bindir

# Build / install the import-chrome utility
make -e -j${nproc} -C import-chrome/build/unix IMAGE=tracy-import-chrome release
cp -v ./import-chrome/build/unix/tracy* $bindir

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
    Dependency("Xorg_xproto_jll", platforms=x11_platforms),
    Dependency("Xorg_kbproto_jll", platforms=x11_platforms),
]

# requires std-c++17, full support in gcc 7+, clang 8+
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8")
