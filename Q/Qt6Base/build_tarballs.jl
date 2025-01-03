# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Qt6Base"
version = v"6.8.1"

# Set this to true first when updating the version. It will build only for the host (linux musl).
# After that JLL is in the registyry, set this to false to build for the other platforms, using
# this same package as host build dependency.
const host_build = false

# Collection of sources required to build qt6
sources = [
    ArchiveSource("https://download.qt.io/official_releases/qt/$(version.major).$(version.minor)/$version/submodules/qtbase-everywhere-src-$version.tar.xz",
                  "40b14562ef3bd779bc0e0418ea2ae08fa28235f8ea6e8c0cb3bce1d6ad58dcaf"),
    ArchiveSource("https://github.com/roblabla/MacOSX-SDKs/releases/download/13.3/MacOSX13.3.sdk.tar.xz",
                  "e5d0f958a079106234b3a840f93653308a76d3dcea02d3aa8f2841f8df33050c"),
    ArchiveSource("https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v10.0.0.tar.bz2",
                  "ba6b430aed72c63a3768531f6a3ffc2b0fde2c57a3b251450dcf489a894f0894"),
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
        apple_sdk_root=$WORKSPACE/srcdir/MacOSX13.3.sdk
        sed -i "s!/opt/x86_64-apple-darwin14/x86_64-apple-darwin14/sys-root!$apple_sdk_root!" $CMAKE_TARGET_TOOLCHAIN
        sed -i "s!/opt/x86_64-apple-darwin14/x86_64-apple-darwin14/sys-root!$apple_sdk_root!" /opt/bin/$bb_full_target/$target-clang++
        deployarg="-DCMAKE_OSX_DEPLOYMENT_TARGET=11"
        export LDFLAGS="-L${libdir}/darwin -lclang_rt.osx"
        sed -i 's/exit 1/#exit 1/' /opt/bin/$bb_full_target/$target-clang++
        ../qtbase-everywhere-src-*/configure -prefix $prefix $commonoptions -- $commoncmakeoptions -DQT_INTERNAL_APPLE_SDK_VERSION=13.3 -DCMAKE_SYSROOT=$apple_sdk_root -DCMAKE_FRAMEWORK_PATH=$apple_sdk_root/System/Library/Frameworks $deployarg -DCUPS_INCLUDE_DIR=$apple_sdk_root/usr/include -DCUPS_LIBRARIES=$apple_sdk_root/usr/lib/libcups.tbd -DQT_FEATURE_vulkan=OFF
        sed -i 's/#exit 1/exit 1/' /opt/bin/$bb_full_target/$target-clang++
    ;;

    *freebsd*)
        sed -i 's/-Wl,--no-undefined//' $qtsrcdir/mkspecs/freebsd-clang/qmake.conf
        sed -i 's/-Wl,--no-undefined//' $qtsrcdir/cmake/QtFlagHandlingHelpers.cmake
        sed -i 's/exit 1/#exit 1/' /opt/bin/$bb_full_target/$target-clang++
        ../qtbase-everywhere-src-*/configure -prefix $prefix $commonoptions -fontconfig -- $commoncmakeoptions -DQT_PLATFORM_DEFINITION_DIR=$host_prefix/mkspecs/freebsd-clang -DQT_FEATURE_xcb=ON
        sed -i 's/#exit 1/exit 1/' /opt/bin/$bb_full_target/$target-clang++
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

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
if host_build
    platforms = [Platform("x86_64", "linux",cxxstring_abi=:cxx11,libc="musl")]
    platforms_macos = AbstractPlatform[]
else
    platforms = expand_cxxstring_abis(filter(!Sys.isapple, supported_platforms()))
    filter!(p -> arch(p) != "armv6l", platforms) # No OpenGL on armv6
    platforms_macos = [ Platform("x86_64", "macos"), Platform("aarch64", "macos") ]
end

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

products_macos = [
    FrameworkProduct("QtConcurrent", :libqt6concurrent),
    FrameworkProduct("QtCore", :libqt6core),
    FrameworkProduct("QtDBus", :libqt6dbus),
    FrameworkProduct("QtGui", :libqt6gui),
    FrameworkProduct("QtNetwork", :libqt6network),
    FrameworkProduct("QtOpenGL", :libqt6opengl),
    FrameworkProduct("QtOpenGLWidgets", :libqt6openglwidgets),
    FrameworkProduct("QtPrintSupport", :libqt6printsupport),
    FrameworkProduct("QtSql", :libqt6sql),
    FrameworkProduct("QtTest", :libqt6test),
    FrameworkProduct("QtWidgets", :libqt6widgets),
    FrameworkProduct("QtXml", :libqt6xml),
]

# We must use the same version of LLVM for the build toolchain and LLVMCompilerRT_jll
llvm_version = v"16.0.6"

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

include("../../fancy_toys.jl")

@static if !host_build
    if any(should_build_platform.(triplet.(platforms_macos)))
        build_tarballs(ARGS, name, version, sources, script, platforms_macos, products_macos, dependencies; preferred_gcc_version = v"10", preferred_llvm_version=llvm_version, julia_compat="1.6")
    end
end
if any(should_build_platform.(triplet.(platforms)))
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"10", preferred_llvm_version=llvm_version, julia_compat="1.6")
end
