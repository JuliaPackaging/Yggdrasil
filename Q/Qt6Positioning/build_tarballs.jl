# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Qt6Positioning"
version = v"6.8.2"

# Collection of sources required to build qt6
sources = [
    ArchiveSource("https://download.qt.io/official_releases/qt/$(version.major).$(version.minor)/$version/submodules/qtpositioning-everywhere-src-$version.tar.xz",
                  "df30664f4e936466a7e1157ff26abc61efb5e94c9eb8750e1bcdffeec95db8e5"),
]

script = raw"""
cd $WORKSPACE/srcdir/qt*

cmake -G Ninja \
    -DQT_HOST_PATH=$host_prefix \
    -DPython_ROOT_DIR=/usr \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=$host_prefix \
    -DCMAKE_FIND_ROOT_PATH=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DQT_NO_APPLE_SDK_AND_XCODE_CHECK=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -B build

cmake --build build --parallel ${nproc}
cmake --install build

install_license LICENSES/LGPL-3.0-only.txt
"""

# Get the common Qt platforms
include("../Qt6Base/common.jl")

# The products that we will ensure are always built
products = [
    LibraryProduct(["Qt6Positioning", "libQt6Positioning", "QtPositioning"], :libqt6positioning),
    LibraryProduct(["Qt6PositioningQuick", "libQt6PositioningQuick", "QtPositioningQuick"], :libqt6positioningquick),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("Qt6Base_jll"),
    HostBuildDependency("Qt6Declarative_jll"),
    Dependency("Qt6Base_jll"; compat="="*string(version)),
    Dependency("Qt6Declarative_jll"; compat="="*string(version)),
]

build_qt(name, version, sources, script, products, dependencies)
