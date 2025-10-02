# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Qt6Base"
version = v"6.8.2"

# Set this to true first when updating the version. It will build only for the host (linux musl).
# After that JLL is in the registry, set this to false to build for the other platforms, using
# this same package as host build dependency.
const host_build = false

# Collection of sources required to build qt6
sources = [
    ArchiveSource("https://download.qt.io/official_releases/qt/$(version.major).$(version.minor)/$version/submodules/qtbase-everywhere-src-$version.tar.xz",
                  "012043ce6d411e6e8a91fdc4e05e6bedcfa10fcb1347d3c33908f7fdd10dfe05"),
    ArchiveSource("https://github.com/roblabla/MacOSX-SDKs/releases/download/macosx14.0/MacOSX14.0.sdk.tar.xz",
                  "4a31565fd2644d1aec23da3829977f83632a20985561a2038e198681e7e7bf49"),
    ArchiveSource("https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v11.0.1.tar.bz2",
                  "3f66bce069ee8bed7439a1a13da7cb91a5e67ea6170f21317ac7f5794625ee10"),
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir

BIN_DIR="/opt/bin/${bb_full_target}"

mkdir build
cd build/

qtsrcdir=`ls -d ../qtbase-everywhere-src-*`

atomic_patch -p1 -d "${qtsrcdir}" ../patches/mingw-mac.patch

commonoptions=" \
-opensource -confirm-license \
-openssl-linked  -nomake examples -release \
"

commoncmakeoptions="-DCMAKE_PREFIX_PATH=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DQT_HOST_PATH=$host_prefix -DQT_FEATURE_openssl_linked=ON"

export LD_LIBRARY_PATH=$host_libdir:$host_prefix/lib64:$LD_LIBRARY_PATH
export OPENSSL_LIBS="-L${libdir} -lssl -lcrypto"

# temporarily allow march during configure
sed -i 's/exit 1/#exit 1/' /opt/bin/$bb_full_target/$target-g++

case "$bb_full_target" in

    x86_64-linux-musl-libgfortran5-cxx11)
        sed -i 's/exit 1/#exit 1/' $HOSTCXX
        ../qtbase-everywhere-src-*/configure -prefix $prefix $commonoptions -fontconfig -- -DCMAKE_PREFIX_PATH=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN} -DQT_FEATURE_xcb=ON
        sed -i 's/#exit 1/exit 1/' $HOSTCXX
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
        ../qtbase-everywhere-src-*/configure -prefix $prefix -opensource -confirm-license -nomake examples -release -opengl dynamic -- -DCMAKE_PREFIX_PATH=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DQT_HOST_PATH=$host_prefix
    ;;

    *apple-darwin*)
        apple_sdk_root=$WORKSPACE/srcdir/MacOSX14.0.sdk
        sed -i "s!/opt/$target/$target/sys-root!$apple_sdk_root!" $CMAKE_TARGET_TOOLCHAIN
        sed -i "s!/opt/$target/$target/sys-root!$apple_sdk_root!" /opt/bin/$bb_full_target/$target-clang++
        deployarg="-DCMAKE_OSX_DEPLOYMENT_TARGET=12"
        export LDFLAGS="-L${libdir}/darwin -lclang_rt.osx"
        export MACOSX_DEPLOYMENT_TARGET=12
        export OBJCFLAGS="-D__ENVIRONMENT_OS_VERSION_MIN_REQUIRED__=120000"
        export OBJCXXFLAGS=$OBJCFLAGS
        export CXXFLAGS=$OBJCFLAGS
        sed -i 's/exit 1/#exit 1/' /opt/bin/$bb_full_target/$target-clang++
        ../qtbase-everywhere-src-*/configure -prefix $prefix $commonoptions -- $commoncmakeoptions \
            -DQT_INTERNAL_APPLE_SDK_VERSION=14 -DQT_INTERNAL_XCODE_VERSION=15 -DCMAKE_SYSROOT=$apple_sdk_root \
            -DCMAKE_FRAMEWORK_PATH=$apple_sdk_root/System/Library/Frameworks $deployarg \
            -DCUPS_INCLUDE_DIR=$apple_sdk_root/usr/include -DCUPS_LIBRARIES=$apple_sdk_root/usr/lib/libcups.tbd \
            -DQT_FEATURE_vulkan=OFF 
        sed -i 's/#exit 1/exit 1/' /opt/bin/$bb_full_target/$target-clang++
    ;;

    *freebsd*)
        sed -i 's/-Wl,--no-undefined//' $qtsrcdir/mkspecs/freebsd-clang/qmake.conf
        sed -i 's/-Wl,--no-undefined//' $qtsrcdir/cmake/QtFlagHandlingHelpers.cmake
        sed -i 's/exit 1/#exit 1/' /opt/bin/$bb_full_target/$target-clang++
        ../qtbase-everywhere-src-*/configure -prefix $prefix $commonoptions -fontconfig -- $commoncmakeoptions -DQT_PLATFORM_DEFINITION_DIR=$host_prefix/mkspecs/freebsd-clang -DQT_FEATURE_xcb=ON
        sed -i 's/#exit 1/exit 1/' /opt/bin/$bb_full_target/$target-clang++
    ;;

    *i686-linux-musl*)
        ../qtbase-everywhere-src-*/configure -verbose -prefix $prefix $commonoptions -fontconfig -no-stack-protector -- $commoncmakeoptions -DQT_FEATURE_xcb=ON
    ;;

    *)
        echo "#define ELFOSABI_GNU 3" >> /opt/$target/$target/sys-root/usr/include/elf.h
        echo "#define EM_AARCH64 183" >> /opt/$target/$target/sys-root/usr/include/elf.h
        echo "#define EM_BLACKFIN 106" >> /opt/$target/$target/sys-root/usr/include/elf.h
        ../qtbase-everywhere-src-*/configure -verbose -prefix $prefix $commonoptions -fontconfig -- $commoncmakeoptions -DQT_FEATURE_xcb=ON
    ;;
esac

# reinstate march restriction for build
sed -i 's/#exit 1/exit 1/' /opt/bin/$bb_full_target/$target-g++

cmake --build . --parallel ${nproc}
cmake --install .
install_license $WORKSPACE/srcdir/qtbase-everywhere-src-*/LICENSES/LGPL-3.0-only.txt
"""

# Get the common Qt platforms
include("common.jl")

# The products that we will ensure are always built
products = [
    LibraryProduct(["Qt6Concurrent", "libQt6Concurrent", "QtConcurrent"], :libqt6concurrent),
    LibraryProduct(["Qt6Core", "libQt6Core", "QtCore"], :libqt6core),
    LibraryProduct(["Qt6DBus", "libQt6DBus", "QtDBus"], :libqt6dbus),
    LibraryProduct(["Qt6Gui", "libQt6Gui", "QtGui"], :libqt6gui),
    LibraryProduct(["Qt6Network", "libQt6Network", "QtNetwork"], :libqt6network),
    LibraryProduct(["Qt6OpenGL", "libQt6OpenGL", "QtOpenGL"], :libqt6opengl),
    LibraryProduct(["Qt6OpenGLWidgets", "libQt6OpenGLWidgets", "QtOpenGLWidgets"], :libqt6openglwidgets),
    LibraryProduct(["Qt6PrintSupport", "libQt6PrintSupport", "QtPrintSupport"], :libqt6printsupport),
    LibraryProduct(["Qt6Sql", "libQt6Sql", "QtSql"], :libqt6sql),
    LibraryProduct(["Qt6Test", "libQt6Test", "QtTest"], :libqt6test),
    LibraryProduct(["Qt6Widgets", "libQt6Widgets", "QtWidgets"], :libqt6widgets),
    LibraryProduct(["Qt6Xml", "libQt6Xml", "QtXml"], :libqt6xml),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libinput_jll"),
    Dependency("Xorg_libXext_jll"),
    Dependency("Xorg_libxcb_jll"),
    Dependency("Xorg_xcb_util_wm_jll"),
    Dependency("Xorg_xcb_util_cursor_jll"),
    Dependency("Xorg_xcb_util_image_jll"),
    Dependency("Xorg_xcb_util_keysyms_jll"),
    Dependency("Xorg_xcb_util_renderutil_jll"),
    Dependency("Xorg_libXrender_jll"),
    Dependency("Xorg_libSM_jll"),
    Dependency("xkbcommon_jll"),
    Dependency("Libglvnd_jll"),
    Dependency("Fontconfig_jll"),
    Dependency("Glib_jll", v"2.59.0"; compat="2.59.0"),
    Dependency("Zlib_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("OpenSSL_jll"; compat="3.0.8"),
    Dependency("Vulkan_Loader_jll"),
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=llvm_version)),
    BuildDependency(PackageSpec(name="LLVMCompilerRT_jll", uuid="4e17d02c-6bf5-513e-be62-445f41c75a11", version=llvm_version);
                    platforms=filter(p -> Sys.isapple(p), platforms_macos)),
    BuildDependency("Xorg_libX11_jll"),
    BuildDependency("Xorg_kbproto_jll"),
    BuildDependency("Xorg_renderproto_jll"),
    BuildDependency("Xorg_xproto_jll"),
    BuildDependency("Xorg_glproto_jll"),
    BuildDependency("Vulkan_Headers_jll"),
]

if !host_build
    push!(dependencies, HostBuildDependency("Qt6Base_jll"))
end

# From Qt6Base/common.jl
build_qt(name, version, sources, script, products, dependencies)
