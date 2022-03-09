# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Qt5Charts"
version = v"5.15.2"

# Collection of sources required to build qt5
sources = [
    ArchiveSource("https://download.qt.io/official_releases/qt/$(version.major).$(version.minor)/$version/submodules/qtcharts-everywhere-src-$version.tar.xz",
                  "e0750e4195bd8a8b9758ab4d98d437edbe273cd3d289dd6a8f325df6d13f3d11"),
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

qtsrcdir=`ls -d ../qtcharts-*`

qmake $qtsrcdir
make -j${nproc}

# It appends the root path here with the qmake dir, which is /workspace/artifacts/blah...
make INSTALL_ROOT=$PWD/dummyroot install
rsync -ua dummyroot/workspace/*/destdir/* $prefix

install_license $qtsrcdir/LICENSE.GPL3

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
platforms_macos = [ Platform("x86_64", "macos") ]

# The products that we will ensure are always built
products = [
    FileProduct(["qml/QtCharts"], :charts),
    LibraryProduct(["Qt5Charts", "libQt5Charts", "QtCharts"], :libqt5charts),
]

products_macos = [
    FileProduct(["qml/QtCharts"], :charts),
    FrameworkProduct("QtCharts", :libqt5charts),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Qt5Declarative_jll"),
]

include("../../fancy_toys.jl")

if any(should_build_platform.(triplet.(platforms_linux)))
    build_tarballs(ARGS, name, version, sources, script, platforms_linux, products, dependencies; preferred_gcc_version = v"7")
end
if any(should_build_platform.(triplet.(platforms_win)))
    build_tarballs(ARGS, name, version, sources, script, platforms_win, products, dependencies; preferred_gcc_version = v"8")
end
if any(should_build_platform.(triplet.(platforms_macos)))
    build_tarballs(ARGS, name, version, sources, script, platforms_macos, products_macos, dependencies; preferred_gcc_version = v"7")
end
