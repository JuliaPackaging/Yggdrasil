# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Qt5QuickControls"
version = v"5.15.3"

# Collection of sources required to build qt5
sources = [
    ArchiveSource("https://download.qt.io/official_releases/qt/$(version.major).$(version.minor)/$version/submodules/qtquickcontrols-everywhere-opensource-src-$version.tar.xz",
                  "4034afce2e8afde4c4cb5e3be3ce240d00647fa0d292f4cd1ac4454ce40230f0"),
]

script = raw"""
# We need to make sure qmake is a copy and not a symlink for the Qt installation paths to be correct:
prefixqmake=$(which qmake)
realqmake=$(readlink $prefixqmake)
rm $prefixqmake
cp $bindir/$realqmake $prefixqmake

case "$target" in
    *apple-darwin*)
        ln -s $libdir/QtCore.framework/Headers $includedir/QtCore
        export QT_MAC_SDK_NO_VERSION_CHECK=1        
        ;;
esac

cd $WORKSPACE/srcdir
mkdir build
cd build/

qtsrcdir=`ls -d ../qtquickcontrols-*`

qmake $qtsrcdir
make -j${nproc}

# It appends the root path here with the qmake dir, which is /workspace/artifacts/blah...
make INSTALL_ROOT=$PWD/dummyroot install
rsync -ua dummyroot/workspace/*/destdir/* $prefix

install_license $qtsrcdir/LICENSE.LGPL3

case "$target" in
    *apple-darwin*)
        rm $includedir/QtCore
        ;;
esac
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms_linux = [
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("armv7l", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "freebsd"),
    Platform("powerpc64le", "linux"; libc="glibc"),
]
platforms_linux = expand_cxxstring_abis(platforms_linux)
platforms_win = expand_cxxstring_abis([Platform("x86_64", "windows"), Platform("i686", "windows")])
platforms_macos = [ Platform("x86_64", "macos"), Platform("aarch64", "macos") ]

# The products that we will ensure are always built
products = [
    FileProduct(["qml/QtQuick/Controls"], :quickcontrols),
]

products_macos = products

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Qt5Declarative_jll"),
]

include("../../fancy_toys.jl")

julia_compat = "1.6"

if any(should_build_platform.(triplet.(platforms_linux)))
    build_tarballs(ARGS, name, version, sources, script, platforms_linux, products, dependencies; preferred_gcc_version = v"7", julia_compat)
end
if any(should_build_platform.(triplet.(platforms_win)))
    build_tarballs(ARGS, name, version, sources, script, platforms_win, products, dependencies; preferred_gcc_version = v"8", julia_compat)
end
if any(should_build_platform.(triplet.(platforms_macos)))
    build_tarballs(ARGS, name, version, sources, script, platforms_macos, products_macos, dependencies; preferred_gcc_version = v"7", julia_compat)
end
