# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Qt6Quick3D"
version = v"6.8.2"

host_build = false

# Collection of sources required to build qt6
sources = [
    ArchiveSource("https://download.qt.io/official_releases/qt/$(version.major).$(version.minor)/$version/submodules/qtquick3d-everywhere-src-$version.tar.xz",
                  "084cebccb8c5b1c6bafb7756ab89b08ced23c20cd2e996ed54909a154a9f0b6d"),
    ArchiveSource("https://github.com/roblabla/MacOSX-SDKs/releases/download/macosx14.0/MacOSX14.0.sdk.tar.xz",
                  "4a31565fd2644d1aec23da3829977f83632a20985561a2038e198681e7e7bf49"),
]

script = raw"""
cd $WORKSPACE/srcdir

mkdir build
cd build/
qtsrcdir=`ls -d ../qtquick3d-*`

if [[ $bb_full_target == *"musl"* ]]; then
    # secure_getenv is undefined on the musl platforms
    sed -i "s/HAVE_SECURE_GETENV//" $qtsrcdir/src/3rdparty/openxr/CMakeLists.txt
fi

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
    LibraryProduct(["Qt6Quick3D", "libQt6Quick3D", "QtQuick3D"], :libqt6quick3d),
    LibraryProduct(["Qt6Quick3DAssetImport", "libQt6Quick3DAssetImport", "QtQuick3DAssetImport"], :libqt6quick3dassetimport),
    LibraryProduct(["Qt6Quick3DAssetUtils", "libQt6Quick3DAssetUtils", "QtQuick3DAssetUtils"], :libqt6quick3dassetutils),
    LibraryProduct(["Qt6Quick3DEffects", "libQt6Quick3DEffects", "QtQuick3DEffects"], :libqt6quick3deffects),
    LibraryProduct(["Qt6Quick3DGlslParser", "libQt6Quick3DGlslParser", "QtQuick3DGlslParser"], :libqt6quick3dglslparser),
    LibraryProduct(["Qt6Quick3DHelpers", "libQt6Quick3DHelpers", "QtQuick3DHelpers"], :libqt6quick3dhelpers),
    LibraryProduct(["Qt6Quick3DHelpersImpl", "libQt6Quick3DHelpersImpl", "QtQuick3DHelpersImpl"], :libqt6quick3dhelpersimpl),
    LibraryProduct(["Qt6Quick3DIblBaker", "libQt6Quick3DIblBaker", "QtQuick3DIblBaker"], :libqt6quick3diblbaker),
    LibraryProduct(["Qt6Quick3DParticleEffects", "libQt6Quick3DParticleEffects", "QtQuick3DParticleEffects"], :libqt6quick3dparticleeffects),
    LibraryProduct(["Qt6Quick3DParticles", "libQt6Quick3DParticles", "QtQuick3DParticles"], :libqt6quick3dparticles),
    LibraryProduct(["Qt6Quick3DRuntimeRender", "libQt6Quick3DRuntimeRender", "QtQuick3DRuntimeRender"], :libqt6quick3druntimerender),
    LibraryProduct(["Qt6Quick3DUtils", "libQt6Quick3DUtils", "QtQuick3DUtils"], :libqt6quick3dutils),
    LibraryProduct(["Qt6Quick3DXr", "libQt6Quick3DXr", "QtQuick3DXr"], :libqt6quick3dxr),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("Qt6Base_jll"),
    HostBuildDependency("Qt6Declarative_jll"),
    HostBuildDependency("Qt6ShaderTools_jll"),
    Dependency("Qt6Base_jll"; compat="="*string(version)),
    Dependency("Qt6Declarative_jll"; compat="="*string(version)),
    Dependency("Qt6ShaderTools_jll"; compat="="*string(version)),
    Dependency("Qt6QuickTimeline_jll"; compat="="*string(version)),
    BuildDependency("Vulkan_Headers_jll"),
]

if !host_build
    push!(dependencies, HostBuildDependency("Qt6Quick3D_jll"))
end

if should_build_platform(Platform("x86_64", "FreeBSD"))
    # OpenXR (even the builtin one) can't be built on FreeBSD apparently, so remove it from the product list there.
    pop!(products)
end
build_qt(name, version, sources, script, products, dependencies)
