# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Qt6Base"
version = v"6.0.3"

# Collection of sources required to build qt6
sources = [
    ArchiveSource("https://download.qt.io/official_releases/qt/$(version.major).$(version.minor)/$version/submodules/qtbase-everywhere-src-$version.tar.xz",
                  "1a45b61c2a349964625c50e3ea40cbb309e269762dd0786397e0e18e7e10d394"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.14.sdk.tar.xz",
                  "0f03869f72df8705b832910517b47dd5b79eb4e160512602f593ed243b28715f")
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

export OPENSSL_LIBS="-L${libdir} -lssl -lcrypto"

sed -i 's/-march=haswell/-mavx2/' $qtsrcdir/cmake/QtCompilerOptimization.cmake

case "$target" in

    x86_64-linux-musl*)
        ../qtbase-everywhere-src-*/configure -prefix $prefix $commonoptions -fontconfig -- -DCMAKE_PREFIX_PATH=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN}
    ;;
esac

cmake --build . --parallel
cmake --install .
$BUILD_STRIP $bindir/qmake
install_license $WORKSPACE/srcdir/qtbase-everywhere-src-*/LICENSE.LGPLv3
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms_linux = [
    Platform("x86_64", "linux"; libc="musl"),
]
platforms_linux = expand_cxxstring_abis(platforms_linux)
# platforms_win = expand_cxxstring_abis([Platform("x86_64", "windows"), Platform("i686", "windows")])
# platforms_macos = [ Platform("x86_64", "macos") ]

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
]

include("../../fancy_toys.jl")

if any(should_build_platform.(triplet.(platforms_linux)))
    build_tarballs(ARGS, name, version, sources, script, platforms_linux, products, dependencies; preferred_gcc_version = v"8")
end
# if any(should_build_platform.(triplet.(platforms_win)))
#     build_tarballs(ARGS, name, version, sources, script, platforms_win, products, dependencies; preferred_gcc_version = v"8")
# end
# if any(should_build_platform.(triplet.(platforms_macos)))
#     build_tarballs(ARGS, name, version, sources, script, platforms_macos, products_macos, dependencies; preferred_gcc_version = v"8")
# end
