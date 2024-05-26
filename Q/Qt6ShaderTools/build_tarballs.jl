# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Qt6ShaderTools"
version = v"6.7.1"

# Set this to true first when updating the version. It will build only for the host (linux musl).
# After that JLL is in the registyry, set this to false to build for the other platforms, using
# this same package as host build dependency.
const host_build = false

# Collection of sources required to build qt6
sources = [
    ArchiveSource("https://download.qt.io/official_releases/qt/$(version.major).$(version.minor)/$version/submodules/qtshadertools-everywhere-src-$version.tar.xz",
                  "e585e3a985b2e2bad8191a84489a04e69c3defc6022a8e746aad22a1f17910c2"),
    ArchiveSource("https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v10.0.0.tar.bz2",
                  "ba6b430aed72c63a3768531f6a3ffc2b0fde2c57a3b251450dcf489a894f0894")
]

script = raw"""
cd $WORKSPACE/srcdir

mkdir build
cd build/
qtsrcdir=`ls -d ../qtshadertools-*`

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

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
if host_build
    platforms = [Platform("x86_64", "linux",cxxstring_abi=:cxx11,libc="musl")]
else
    platforms = expand_cxxstring_abis(filter(!Sys.isapple, supported_platforms()))
    filter!(p -> arch(p) != "armv6l", platforms) # No OpenGL on armv6
    platforms_macos = [ Platform("x86_64", "macos"), Platform("aarch64", "macos") ]
end

# The products that we will ensure are always built
products = [
    LibraryProduct(["Qt6ShaderTools", "libQt6ShaderTools", "QtShaderTools"], :libqt6shadertools),
]

products_macos = [
    FrameworkProduct("QtShaderTools", :libqt6shadertools),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("Qt6Base_jll"),
    Dependency("Qt6Base_jll"; compat="="*string(version)),
]

if !host_build
    push!(dependencies, HostBuildDependency("Qt6ShaderTools_jll"))
end

include("../../fancy_toys.jl")

@static if !host_build
    if any(should_build_platform.(triplet.(platforms_macos)))
        build_tarballs(ARGS, name, version, sources, script, platforms_macos, products_macos, dependencies; preferred_gcc_version = v"10", julia_compat="1.6")
    end
end
if any(should_build_platform.(triplet.(platforms)))
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"10", julia_compat="1.6")
end
