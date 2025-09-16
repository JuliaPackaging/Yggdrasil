# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Qt6QuickTimeline"
version = v"6.8.2"

# Collection of sources required to build qt6
sources = [
    ArchiveSource("https://download.qt.io/official_releases/qt/$(version.major).$(version.minor)/$version/submodules/qtquicktimeline-everywhere-src-$version.tar.xz",
                  "c33dbceed9fabb3d7f6731a68aee602bad5a04bb6f0a473792e61858c0bc1aaa"),
    ArchiveSource("https://github.com/roblabla/MacOSX-SDKs/releases/download/macosx14.0/MacOSX14.0.sdk.tar.xz",
                  "4a31565fd2644d1aec23da3829977f83632a20985561a2038e198681e7e7bf49"),
]

script = raw"""
cd $WORKSPACE/srcdir

mkdir build
cd build/
qtsrcdir=`ls -d ../qtquicktimeline-*`

case "$bb_full_target" in

    x86_64-linux-musl-libgfortran5-cxx11)
        cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_FIND_ROOT_PATH=$prefix -DCMAKE_BUILD_TYPE=Release $qtsrcdir
    ;;

    *apple-darwin*)
        apple_sdk_root=$WORKSPACE/srcdir/MacOSX14.0.sdk
        sed -i "s!/opt/$target/$target/sys-root!$apple_sdk_root!" $CMAKE_TARGET_TOOLCHAIN
        sed -i "s!/opt/$target/$target/sys-root!$apple_sdk_root!" /opt/bin/$bb_full_target/$target-clang++
        export MACOSX_DEPLOYMENT_TARGET=12
        export OBJCFLAGS="-D__ENVIRONMENT_OS_VERSION_MIN_REQUIRED__=120000"
        export OBJCXXFLAGS=$OBJCFLAGS
        export CXXFLAGS=$OBJCFLAGS
        cmake -G Ninja -DQT_HOST_PATH=$host_prefix \
            -DPython_ROOT_DIR=/usr \
            -DCMAKE_INSTALL_PREFIX=${prefix} \
            -DCMAKE_PREFIX_PATH=$host_prefix \
            -DCMAKE_FIND_ROOT_PATH=$prefix \
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
            -DCMAKE_SYSROOT=$apple_sdk_root -DCMAKE_FRAMEWORK_PATH=$apple_sdk_root/System/Library/Frameworks -DCMAKE_OSX_DEPLOYMENT_TARGET=11 \
            -DQT_NO_APPLE_SDK_AND_XCODE_CHECK=ON \
            -DCMAKE_BUILD_TYPE=Release \
        $qtsrcdir
    ;;

    *)
        cmake -DQT_HOST_PATH=$host_prefix -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_FIND_ROOT_PATH=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release $qtsrcdir
    ;;

esac

cmake --build . --parallel ${nproc}
cmake --install .
install_license $WORKSPACE/srcdir/qt*-src-*/LICENSES/GPL-3.0-only.txt
"""
# Get the common Qt platforms
include("../Qt6Base/common.jl")

# The products that we will ensure are always built
products = [
    LibraryProduct(["Qt6QuickTimeline", "libQt6QuickTimeline", "QtQuickTimeline"], :libqt6timeline),
    LibraryProduct(["Qt6QuickTimelineBlendTrees", "libQt6QuickTimelineBlendTrees", "QtQuickTimelineBlendTrees"], :libqt6timelineblendtrees),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("Qt6Base_jll"),
    HostBuildDependency("Qt6Declarative_jll"),
    Dependency("Qt6Base_jll"; compat="="*string(version)),
    Dependency("Qt6Declarative_jll"; compat="="*string(version)),
]

build_qt(name, version, sources, script, products, dependencies)
