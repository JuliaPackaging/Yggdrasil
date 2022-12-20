# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Qt5Wayland"
version = v"5.15.2"

# Collection of sources required to build qt5
sources = [
    ArchiveSource("https://download.qt.io/official_releases/qt/$(version.major).$(version.minor)/$version/submodules/qtwayland-everywhere-src-$version.tar.xz",
                  "193732229ff816f3aaab9a5e2f6bed71ddddbf1988ce003fe8dd84a92ce9aeb5"),
]

script = raw"""
cd $WORKSPACE/srcdir
mkdir build
cd build/

qtsrcdir=`ls -d ../qtwayland-*`

qmake $qtsrcdir
make -j${nproc}

# It appends the root path here with the qmake dir, which is /workspace/artifacts/blah...
make INSTALL_ROOT=$PWD/dummyroot install
rsync -ua dummyroot/workspace/*/artifacts/*/* $prefix

sed -i "s?^prefix=.*?prefix=$prefix?" $prefix/lib/pkgconfig/Qt5WaylandClient.pc
sed -i "s?^prefix=.*?prefix=$prefix?" $prefix/lib/pkgconfig/Qt5WaylandCompositor.pc

install_license $qtsrcdir/LICENSE.LGPL3
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms_linux = [
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("armv7l", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="glibc"),
]
platforms_linux = expand_cxxstring_abis(platforms_linux)

# The products that we will ensure are always built
products = [
    LibraryProduct(["Qt5WaylandClient", "libQt5WaylandClient"], :libqt5waylandclient),
    LibraryProduct(["Qt5WaylandCompositor", "libQt5WaylandCompositor"], :libqt5waylandcompositor),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("Wayland_jll"),
    Dependency("Qt5Base_jll"),
    Dependency("Wayland_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms_linux, products, dependencies; preferred_gcc_version = v"7")
