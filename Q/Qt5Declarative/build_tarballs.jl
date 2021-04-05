# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Qt5Declarative"
version = v"5.15.2"

# Collection of sources required to build qt5
sources = [
    ArchiveSource("https://download.qt.io/official_releases/qt/$(version.major).$(version.minor)/$version/submodules/qtdeclarative-everywhere-src-$version.tar.xz",
                  "c600d09716940f75d684f61c5bdaced797f623a86db1627da599027f6c635651"),
]

script = raw"""
case "$target" in
    *apple-darwin*)
        ln -s $libdir/QtCore.framework/Headers $includedir/QtCore
        export QT_MAC_SDK_NO_VERSION_CHECK=1        
        ;;
esac

cd $WORKSPACE/srcdir
mkdir build
cd build/

qtsrcdir=`ls -d ../qtdeclarative-*`

qmake $qtsrcdir
make -j${nproc}

# It appends the root path here with the qmake dir, which is /workspace/artifacts/blah...
make INSTALL_ROOT=$PWD/dummyroot install
rsync -ua dummyroot/workspace/*/artifacts/*/* $prefix

sed -i "s?^prefix=.*?prefix=$prefix?" $prefix/lib/pkgconfig/Qt5*.pc

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
platforms_macos = [ Platform("x86_64", "macos") ]

# The products that we will ensure are always built
products = [
    LibraryProduct(["Qt5Qml", "libQt5Qml", "QtQml"], :libqt5qml),
    LibraryProduct(["Qt5QmlModels", "libQt5QmlModels", "QtQmlModels"], :libqt5qmlmodels),
    LibraryProduct(["Qt5QmlWorkerScript", "libQt5QmlWorkerScript", "QtQmlWorkerScript"], :libqt5qmlworkerscript),
    LibraryProduct(["Qt5Quick", "libQt5Quick", "QtQuick"], :libqt5quick),
    LibraryProduct(["Qt5QuickParticles", "libQt5QuickParticles", "QtQuickParticles"], :libqt5quickparticles),
    LibraryProduct(["Qt5QuickShapes", "libQt5QuickShapes", "QtQuickShapes"], :libqt5quickshapes),
    LibraryProduct(["Qt5QuickTest", "libQt5QuickTest", "QtQuickTest"], :libqt5quicktest),
    LibraryProduct(["Qt5QuickWidgets", "libQt5QuickWidgets", "QtQuickWidgets"], :libqt5quickwidgets),
]

products_macos = [
    FrameworkProduct("QtQml", :libqt5qml),
    FrameworkProduct("QtQmlModels", :libqt5qmlmodels),
    FrameworkProduct("QtQmlWorkerScript", :libqt5qmlworkerscript),
    FrameworkProduct("QtQuick", :libqt5quick),
    FrameworkProduct("QtQuickParticles", :libqt5quickparticles),
    FrameworkProduct("QtQuickShapes", :libqt5quickshapes),
    FrameworkProduct("QtQuickTest", :libqt5quicktest),
    FrameworkProduct("QtQuickWidgets", :libqt5quickwidgets),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Qt5Base_jll"),
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
