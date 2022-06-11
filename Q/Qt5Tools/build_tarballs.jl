# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Qt5Tools"
version = v"5.15.2"

# Collection of sources required to build qt5
sources = [
    ArchiveSource("https://download.qt.io/official_releases/qt/$(version.major).$(version.minor)/$version/submodules/qttools-everywhere-src-$version.tar.xz",
                  "c189d0ce1ff7c739db9a3ace52ac3e24cb8fd6dbf234e49f075249b38f43c1cc"),
]

script = raw"""
cd $WORKSPACE/srcdir
mkdir build
cd build/

qtsrcdir=`ls -d ../qttools-*`

case "$target" in
    *apple-darwin*)
        ln -s $libdir/QtCore.framework/Headers $includedir/QtCore
        ;;
    *freebsd*)
        echo "LIBS += -lxml2 -lz -liconv" >> $qtsrcdir/src/qdoc/qdoc.pro
        ;;
esac

export LLVM_INSTALL_DIR=/opt/x86_64-linux-musl
export QDOC_USE_STATIC_LIBCLANG=true

qmake $qtsrcdir
make -j${nproc}

# It appends the root path here with the qmake dir, which is /workspace/artifacts/blah...
make INSTALL_ROOT=$PWD/dummyroot install
rsync -ua dummyroot/workspace/*/artifacts/*/* $prefix

install_license $qtsrcdir/LICENSE.LGPL3

case "$target" in
    *apple-darwin*)
        rm $includedir/QtCore
        ;;
    *mingw*)
        chmod +x $bindir/*.exe
        ;;
esac
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("armv7l", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "freebsd"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("x86_64", "windows"),
    Platform("i686", "windows"),
    Platform("x86_64", "macos"),
]

platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("qdbus", :qdbus),
    ExecutableProduct("qtdiag", :qtdiag),
    ExecutableProduct("qtpaths", :qtpaths),
    ExecutableProduct("qtplugininfo", :qtplugininfo),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Glib_jll", v"2.59.0"; compat="2.59.0"),
    Dependency("Qt5Base_jll"),
]

include("../../fancy_toys.jl")

# Must match GCC versions of Qt5Base
platforms_win = filter(p -> p.tags["os"] == "windows", platforms)
if any(should_build_platform.(triplet.(platforms_win)))
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8")
else
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7")
end
