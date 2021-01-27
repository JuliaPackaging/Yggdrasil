# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "QtTools"
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

export PATH=$(echo "$PATH" | sed -e "s?${BIN_DIR}:??")
ln -s /opt/bin/x86_64-linux-musl-cxx11/x86_64-linux-musl-g++ /usr/bin/g++

qmake $qtsrcdir

make -j${nproc}

# It appends the root path here with the qmake dir, which is /workspace/artifacts/blah...
make INSTALL_ROOT=$PWD/dummyroot install
rsync -ua dummyroot/workspace/artifacts/*/* $prefix

install_license $qtsrcdir/LICENSE.LGPL3
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
    ExecutableProduct("lrelease", :lrelease),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Qt_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8")
