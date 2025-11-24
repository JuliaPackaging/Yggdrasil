# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "Qt6Positioning"
version = v"6.7.1"

# Collection of sources required to build qt6
sources = [
    ArchiveSource("https://download.qt.io/official_releases/qt/$(version.major).$(version.minor)/$version/submodules/qtpositioning-everywhere-src-$version.tar.xz",
                  "5c2b0d46b8d35126e97c8efe22264b2de7ac1273a5ec38a0314731bb02804f53"),
    ArchiveSource("https://github.com/roblabla/MacOSX-SDKs/releases/download/13.3/MacOSX13.3.sdk.tar.xz",
                  "e5d0f958a079106234b3a840f93653308a76d3dcea02d3aa8f2841f8df33050c"),
]

script = raw"""
cd $WORKSPACE/srcdir

mkdir build
cd build/
qtsrcdir=`ls -d ../qtpositioning-*`

case "$bb_full_target" in

    x86_64-linux-musl-libgfortran5-cxx11)
        cmake \
            -DCMAKE_INSTALL_PREFIX=${prefix} \
            -DCMAKE_FIND_ROOT_PATH=$prefix \
            -DCMAKE_BUILD_TYPE=Release $qtsrcdir
    ;;

    *apple-darwin*)
        apple_sdk_root=$WORKSPACE/srcdir/MacOSX13.3.sdk
        sed -i "s!/opt/x86_64-apple-darwin14/x86_64-apple-darwin14/sys-root!$apple_sdk_root!" $CMAKE_TARGET_TOOLCHAIN
        export LDFLAGS="-L${libdir}/darwin -lclang_rt.osx"
        deployarg="-DCMAKE_OSX_DEPLOYMENT_TARGET=10.14"
        cmake -G Ninja \
            -DQT_HOST_PATH=$host_prefix \
            -DPython_ROOT_DIR=/usr \
            -DCMAKE_INSTALL_PREFIX=${prefix} \
            -DCMAKE_PREFIX_PATH=$host_prefix \
            -DCMAKE_FIND_ROOT_PATH=$prefix \
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
            -DCMAKE_SYSROOT=$apple_sdk_root \
            -DCMAKE_FRAMEWORK_PATH=$apple_sdk_root/System/Library/Frameworks \
            -DCMAKE_OSX_DEPLOYMENT_TARGET=11 \
            -DQT_NO_APPLE_SDK_AND_XCODE_CHECK=ON \
            -DCMAKE_BUILD_TYPE=Release \
        $qtsrcdir
    ;;

    *)
        cmake \
            -DQT_HOST_PATH=$host_prefix \
            -DPython_ROOT_DIR=/usr \
            -DCMAKE_INSTALL_PREFIX=${prefix} \
            -DCMAKE_PREFIX_PATH=$host_prefix \
            -DCMAKE_FIND_ROOT_PATH=$prefix \
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
            -DCMAKE_BUILD_TYPE=Release \
            $qtsrcdir
    ;;

esac

cmake --build . --parallel ${nproc}
cmake --install .
install_license $WORKSPACE/srcdir/qt*-src-*/LICENSES/LGPL-3.0-only.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(filter(!Sys.isapple, supported_platforms()))
filter!(p -> arch(p) != "armv6l", platforms) # No OpenGL on armv6
platforms_macos = [ Platform("x86_64", "macos"), Platform("aarch64", "macos") ]

# The products that we will ensure are always built
products = [
    LibraryProduct(["Qt6Positioning", "libQt6Positioning", "QtPositioning"], :libqt6positioning),
    LibraryProduct(["Qt6PositioningQuick", "libQt6PositioningQuick", "QtPositioningQuick"], :libqt6positioningquick),
]

products_macos = [
    FrameworkProduct("QtPositioning", :libqt6positioning),
    FrameworkProduct("QtPositioningQuick", :libqt6positioningquick),
]

# We must use the same version of LLVM for the build toolchain and LLVMCompilerRT_jll
# LLVM is needed for __isPlatformVersionAtLeast on mac
llvm_version = v"16.0.6"

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=llvm_version)),
    BuildDependency(PackageSpec(name="LLVMCompilerRT_jll", uuid="4e17d02c-6bf5-513e-be62-445f41c75a11", version=llvm_version);
                    platforms=filter(p -> Sys.isapple(p), platforms_macos)),
    HostBuildDependency("Qt6Base_jll"),
    HostBuildDependency("Qt6Declarative_jll"),
    Dependency("Qt6Base_jll"; compat="="*string(version)),
    Dependency("Qt6Declarative_jll"; compat="="*string(version)),
]

if any(should_build_platform.(triplet.(platforms_macos)))
    build_tarballs(ARGS, name, version, sources, script, platforms_macos, products_macos, dependencies; preferred_gcc_version = v"10", julia_compat="1.6")
end

if any(should_build_platform.(triplet.(platforms)))
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"10", julia_compat="1.6")
end
