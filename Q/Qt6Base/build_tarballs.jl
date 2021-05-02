# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Qt6Base"
version = v"6.0.3"

# Collection of sources required to build qt6
sources = [
    ArchiveSource("https://download.qt.io/official_releases/qt/$(version.major).$(version.minor)/$version/submodules/qtbase-everywhere-src-$version.tar.xz",
                  "1a45b61c2a349964625c50e3ea40cbb309e269762dd0786397e0e18e7e10d394"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/11.0-11.1/MacOSX11.1.sdk.tar.xz",
                  "9b86eab03176c56bb526de30daa50fa819937c54b280364784ce431885341bf6"),
]

script = raw"""
cd $WORKSPACE/srcdir

BIN_DIR="/opt/bin/${bb_full_target}"

mkdir build
cd build/

qtsrcdir=`ls -d ../qtbase-everywhere-src-*`

commonoptions=" \
-opensource -confirm-license \
-openssl-linked  -nomake examples -release \
"

commoncmakeoptions="-DCMAKE_PREFIX_PATH=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DQT_HOST_PATH=$host_prefix -DQT_FEATURE_openssl_linked=ON"

export LD_LIBRARY_PATH=$host_libdir:$LD_LIBRARY_PATH
export OPENSSL_LIBS="-L${libdir} -lssl -lcrypto"

sed -i 's/-march=haswell/-mavx2/' $qtsrcdir/cmake/QtCompilerOptimization.cmake
sed -i 's/.*Ws2_32 Crypt32.*//' $qtsrcdir/cmake/FindWrapOpenSSL.cmake
sed -i "s!Qt::GuiPrivate!Qt::GuiPrivate $libdir/clang/11.0.1/lib/darwin/libclang_rt.osx.a!" $qtsrcdir/src/plugins/platforms/cocoa/CMakeLists.txt

case "$target" in

    x86_64-linux-musl*)
        ../qtbase-everywhere-src-*/configure -prefix $prefix $commonoptions -fontconfig -- -DCMAKE_PREFIX_PATH=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN}
    ;;

    *mingw*)
        ../qtbase-everywhere-src-*/configure -prefix $prefix $commonoptions -opengl dynamic -- $commoncmakeoptions
    ;;

    *apple-darwin*)
        # Install 11.1 SDK
        cd $WORKSPACE/srcdir/MacOSX11.1.sdk
        rm -rf /opt/$target/$target/sys-root/System
        rm -rf /opt/$target/$target/sys-root/usr/include/libxml2/
        rsync -a usr/* /opt/$target/$target/sys-root/usr/
        cp -a System /opt/$target/$target/sys-root/
        cd $WORKSPACE/srcdir/build

        ../qtbase-everywhere-src-*/configure -prefix $prefix $commonoptions -- $commoncmakeoptions -DCMAKE_FRAMEWORK_PATH=/opt/$target/$target/sys-root/System/Library/Frameworks -DCMAKE_OSX_DEPLOYMENT_TARGET=10.14 -DCUPS_INCLUDE_DIR=/opt/$target/$target/sys-root/usr/include -DCUPS_LIBRARIES=/opt/$target/$target/sys-root/usr/lib/libcups.tbd
    ;;

    *freebsd*)
        sed -i 's/-Wl,--no-undefined//' $qtsrcdir/mkspecs/freebsd-clang/qmake.conf
        sed -i 's/-Wl,--no-undefined//' $qtsrcdir/cmake/QtFlagHandlingHelpers.cmake
        ../qtbase-everywhere-src-*/configure -prefix $prefix $commonoptions -fontconfig -- $commoncmakeoptions -DQT_PLATFORM_DEFINITION_DIR=$host_prefix/mkspecs/freebsd-clang
    ;;

    *)
        ../qtbase-everywhere-src-*/configure -prefix $prefix $commonoptions -fontconfig -- $commoncmakeoptions
    ;;
esac

cmake --build . --parallel ${nproc}
cmake --install .
install_license $WORKSPACE/srcdir/qtbase-everywhere-src-*/LICENSE.LGPLv3
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(filter(!Sys.isapple, supported_platforms()))
platforms_macos = [ Platform("x86_64", "macos") ]

# The products that we will ensure are always built
products = [
    LibraryProduct(["Qt6Concurrent", "libQt6Concurrent", "QtConcurrent"], :libqt6concurrent),
    LibraryProduct(["Qt6Core", "libQt6Core", "QtCore"], :libqt6core),
    LibraryProduct(["Qt6DBus", "libQt6DBus", "QtDBus"], :libqt6dbus),
    LibraryProduct(["Qt6Gui", "libQt6Gui", "QtGui"], :libqt6gui),
    LibraryProduct(["Qt6Network", "libQt6Network", "QtNetwork"], :libqt6network),
    LibraryProduct(["Qt6OpenGL", "libQt6OpenGL", "QtOpenGL"], :libqt6opengl),
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
    FrameworkProduct("QtPrintSupport", :libqt6printsupport),
    FrameworkProduct("QtSql", :libqt6sql),
    FrameworkProduct("QtTest", :libqt6test),
    FrameworkProduct("QtWidgets", :libqt6widgets),
    FrameworkProduct("QtXml", :libqt6xml),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("Qt6Base_jll"),
    BuildDependency("Xorg_libX11_jll"),
    Dependency("Xorg_libXext_jll"),
    BuildDependency("Xorg_xproto_jll"),
    BuildDependency("Xorg_glproto_jll"),
    Dependency("Xorg_libxcb_jll"),
    Dependency("Xorg_xcb_util_wm_jll"),
    Dependency("Xorg_xcb_util_image_jll"),
    Dependency("Xorg_xcb_util_keysyms_jll"),
    Dependency("Xorg_xcb_util_renderutil_jll"),
    BuildDependency("Xorg_kbproto_jll"),
    BuildDependency("Xorg_renderproto_jll"),
    Dependency("Xorg_libXrender_jll"),
    Dependency("xkbcommon_jll"),
    Dependency("Libglvnd_jll"),
    Dependency("Fontconfig_jll"),
    Dependency("Glib_jll"),
    Dependency("Zlib_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("OpenSSL_jll"),
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=v"11.0.1")),
]

include("../../fancy_toys.jl")

if any(should_build_platform.(triplet.(platforms_macos)))
    build_tarballs(ARGS, name, version, sources, script, platforms_macos, products_macos, dependencies; preferred_gcc_version = v"8", julia_compat="1.6")
end
if any(should_build_platform.(triplet.(platforms)))
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8", julia_compat="1.6")
end
