# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Qt6ShaderTools"
version = v"6.8.2"

# Set this to true first when updating the version. It will build only for the host (linux musl).
# After that JLL is in the registry, set this to false to build for the other platforms, using
# this same package as host build dependency.
const host_build = false

# Collection of sources required to build qt6
sources = [
    ArchiveSource("https://download.qt.io/official_releases/qt/$(version.major).$(version.minor)/$version/submodules/qtshadertools-everywhere-src-$version.tar.xz",
                  "d1d5f90e8885fc70d63ac55a4ce4d9a2688562033a000bc4aff9320f5f551871"),
    ArchiveSource("https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v11.0.1.tar.bz2",
                  "3f66bce069ee8bed7439a1a13da7cb91a5e67ea6170f21317ac7f5794625ee10"),
    ArchiveSource("https://github.com/roblabla/MacOSX-SDKs/releases/download/macosx14.0/MacOSX14.0.sdk.tar.xz",
                  "4a31565fd2644d1aec23da3829977f83632a20985561a2038e198681e7e7bf49"),
]

script = raw"""
cd $WORKSPACE/srcdir

mkdir build
cd build/
qtsrcdir=`ls -d ../qtshadertools-*`

if [[ "${target}" == *apple-darwin* ]]; then
    apple_sdk_root=$WORKSPACE/srcdir/MacOSX14.0.sdk
    sed -i "s!/opt/$target/$target/sys-root!$apple_sdk_root!" $CMAKE_TARGET_TOOLCHAIN
    sed -i "s!/opt/$target/$target/sys-root!$apple_sdk_root!" /opt/bin/$bb_full_target/$target-clang++
    export MACOSX_DEPLOYMENT_TARGET=12
fi

case "$bb_full_target" in

    x86_64-linux-musl-libgfortran5-cxx11)
        cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_FIND_ROOT_PATH=$prefix -DCMAKE_BUILD_TYPE=Release $qtsrcdir
    ;;

    *mingw*)        
        cd $WORKSPACE/srcdir/mingw*/mingw-w64-headers
        ./configure --prefix=/opt/$target/$target/sys-root --enable-sdk=all --host=$target
        make install
        
        cd ../mingw-w64-crt/
        if [ ${target} == "i686-w64-mingw32" ]; then
            _crt_configure_args="--disable-lib64 --enable-lib32"
        elif [ ${target} == "x86_64-w64-mingw32" ]; then
            _crt_configure_args="--disable-lib32 --enable-lib64"
        fi
        ./configure --prefix=/opt/$target/$target/sys-root --enable-sdk=all --host=$target --enable-wildcard ${_crt_configure_args}
        make -j${nproc}
        make install
        
        cd ../mingw-w64-libraries/winpthreads
        ./configure --prefix=/opt/$target/$target/sys-root --host=$target --enable-static --enable-shared
        make -j${nproc}
        make install

        cd $WORKSPACE/srcdir/build
        cmake -DQT_HOST_PATH=$host_prefix -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_FIND_ROOT_PATH=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release $qtsrcdir
    ;;

    *)
        cmake -G Ninja -DQT_HOST_PATH=$host_prefix -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_FIND_ROOT_PATH=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DQT_NO_APPLE_SDK_AND_XCODE_CHECK=ON -DCMAKE_BUILD_TYPE=Release $qtsrcdir
    ;;

esac

cmake --build . --parallel ${nproc}
cmake --install .
install_license $WORKSPACE/srcdir/qt*-src-*/LICENSES/LGPL-3.0-only.txt
"""
# Get the common Qt platforms
include("../Qt6Base/common.jl")

# The products that we will ensure are always built
products = [
    LibraryProduct(["Qt6ShaderTools", "libQt6ShaderTools", "QtShaderTools"], :libqt6shadertools),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("Qt6Base_jll"),
    Dependency("Qt6Base_jll"; compat="="*string(version)),
]

if !host_build
    push!(dependencies, HostBuildDependency("Qt6ShaderTools_jll"))
end

# From ../Qt6Base/common.jl to ensure consistency
build_qt(name, version, sources, script, products, dependencies)
