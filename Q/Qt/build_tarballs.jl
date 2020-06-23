# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Qt"
version = v"5.15.0"

# Collection of sources required to build qt5
sources = [
    ArchiveSource("https://download.qt.io/official_releases/qt/5.15/$version/single/qt-everywhere-src-$version.tar.xz",
                  "22b63d7a7a45183865cc4141124f12b673e7a17b1fe2b91e433f6547c5d548c3"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.14.sdk.tar.xz",
                  "0f03869f72df8705b832910517b47dd5b79eb4e160512602f593ed243b28715f")
]

script = raw"""
cd $WORKSPACE/srcdir
mkdir build
cd build/

commonoptions=" \
-opensource -confirm-license \
-skip qtactiveqt -skip qtandroidextras -skip qtcanvas3d -skip qtconnectivity -skip qtdatavis3d -skip qtdoc -skip qtgamepad \
-skip qtnetworkauth -skip qtpurchasing -skip qtremoteobjects -skip qtscript -skip qtscxml -skip qtsensors -skip qtserialbus \
-skip qtserialport -skip qtspeech -skip qtvirtualkeyboard -skip qtlocation -skip qtwayland -skip qtwebchannel -skip qtwebengine \
-skip qtwebglplugin -skip qtwebsockets -skip qtwebview  -skip qttools -nomake examples -release \
"

case "$target" in

	*86*linux*)
        export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$prefix/share/pkgconfig
        ../qt-everywhere-src-*/configure -L $prefix/lib -I $prefix/include \
            -prefix $prefix $commonoptions \
            -skip qtwinextras -fontconfig
        ln -s /lib64/libc.so.6 /lib64/libc.so
        ;;
        
	*apple-darwin*)
        cd $WORKSPACE/srcdir/MacOSX10.14.sdk
        rm -rf /opt/$target/$target/sys-root/System
        rsync -a usr/* /opt/$target/$target/sys-root/usr/
        cp -a System /opt/$target/$target/sys-root/
        
        cd $WORKSPACE/srcdir/qt-everywhere-src-*/qtbase
        
        cat <<EOT > mkspecs/features/mac/default_pre.prf
CONFIG = asset_catalogs rez \$\$CONFIG
load(default_pre)

QMAKE_ASSET_CATALOGS_APP_ICON = AppIcon

macx-xcode:qtConfig(static): \\
    QMAKE_XCODE_DEBUG_INFORMATION_FORMAT = dwarf

QMAKE_XCODE_LIBRARY_SUFFIX_SETTING = QT_LIBRARY_SUFFIX

xcode_copy_phase_strip_setting.name = COPY_PHASE_STRIP
xcode_copy_phase_strip_setting.value = NO
QMAKE_MAC_XCODE_SETTINGS += xcode_copy_phase_strip_setting
EOT
        
        sed -i '1s;^;QMAKE_MAC_SDK.macosx.Path = '"/opt/$target/$target/sys-root"'\
        QMAKE_MAC_SDK.macosx.SDKVersion = '"10.14"'\
        QMAKE_MAC_SDK.macosx.PlatformPath = '"/opt/$target"'\n;' 'mkspecs/features/mac/sdk.prf'
        echo "" >  mkspecs/features/mac/no_warn_empty_obj_files.prf
        
        sed -i 's!-fuse-ld=x86_64-apple-darwin14!-fuse-ld=/opt/bin/x86_64-apple-darwin14-ld!g' /opt/bin/x86_64-apple-darwin14-clang++
        sed -i 's!-fuse-ld=x86_64-apple-darwin14!-fuse-ld=/opt/bin/x86_64-apple-darwin14-ld!g' /opt/bin/x86_64-apple-darwin14-clang
        
        cd $WORKSPACE/srcdir/build
        apk add g++ linux-headers
        export PATH=$(echo "$PATH" | sed -e 's!/opt/bin:!!')
        export QT_MAC_SDK_NO_VERSION_CHECK=1
        ../qt-everywhere-src-*/configure \
            QMAKE_CXXFLAGS+=-F/opt/$target/$target/sys-root/System/Library/Frameworks \
            QMAKE_RANLIB=/opt/bin/ranlib \
            QMAKE_MACOSX_DEPLOYMENT_TARGET=10.14 \
            -platform linux-g++ -xplatform macx-clang -device-option CROSS_COMPILE=/opt/bin/$target- \
            -prefix $prefix $commonoptions \
            -skip qtwinextras
        ;;
        
	*w64-mingw*)
        apk add g++ linux-headers
        export PATH=$(echo "$PATH" | sed -e 's!/opt/bin:!!')
        
        ../qt-everywhere-src-*/configure -platform linux-g++ -xplatform win32-g++ -device-option CROSS_COMPILE=/opt/bin/$target- \
            -prefix $prefix $commonoptions \
            -opengl desktop
		;;

    *arm-linux*)
        apk add g++ linux-headers
        export PATH=$(echo "$PATH" | sed -e 's!/opt/bin:!!')
        export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$prefix/share/pkgconfig
        export PKG_CONFIG_LIBDIR=$prefix/lib/pkgconfig
        
        ../qt-everywhere-src-*/configure QMAKE_LFLAGS=-liconv -platform linux-g++ -device linux-rasp-pi3-g++ -device-option CROSS_COMPILE=/opt/bin/$target- \
            -extprefix $prefix $commonoptions \
            -skip qtwinextras -fontconfig -sysroot /opt/$target/bin/../$target/sys-root
		;;
esac

make -j${nproc}
make install
install_license $WORKSPACE/srcdir/qt-everywhere-src-*/LICENSE.LGPLv3
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms_linux = [
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:x86_64, libc=:glibc),
]
platforms_linux = expand_cxxstring_abis(platforms_linux)
platforms_win = expand_cxxstring_abis([Windows(:x86_64)])
platforms_macos = [ MacOS(:x86_64) ]

# The products that we will ensure are always built
products = [
    LibraryProduct(["Qt5Core", "libQt5Core", "QtCore"], :libqt5core),
    LibraryProduct(["Qt5Quick", "libQt5Quick", "QtQuick"], :libqt5quick),
    LibraryProduct(["Qt5QuickControls2", "libQt5QuickControls2", "QtQuickControls2"], :libqt5quickcontrols2),
    LibraryProduct(["Qt5Svg", "libQt5Svg", "QtSvg"], :libqt5svg),
    LibraryProduct(["Qt5Widgets", "libQt5Widgets", "QtWidgets"], :libqt5widgets),
]

products_macos = [
    FrameworkProduct("QtCore", :libqt5core),
    FrameworkProduct("QtQuick", :libqt5quick),
    FrameworkProduct("QtQuickControls2", :libqt5quickcontrols2),
    FrameworkProduct("QtSvg", :libqt5svg),
    FrameworkProduct("QtWidgets", :libqt5widgets),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_libX11_jll"),
    BuildDependency("Xorg_libXext_jll"),
    BuildDependency("Xorg_glproto_jll"),
    BuildDependency("Xorg_libxcb_jll"),
    BuildDependency("Xorg_xcb_util_wm_jll"),
    BuildDependency("Xorg_xcb_util_image_jll"),
    BuildDependency("Xorg_xcb_util_keysyms_jll"),
    BuildDependency("Xorg_xcb_util_renderutil_jll"),
    BuildDependency("xkbcommon_jll"),
    BuildDependency("Libglvnd_jll"),
    BuildDependency("Fontconfig_jll"),
    BuildDependency("Glib_jll"),
]

include("../../fancy_toys.jl")

if any(should_build_platform.(triplet.(platforms_linux)))
    build_tarballs(ARGS, name, version, sources, script, platforms_linux, products, dependencies; preferred_gcc_version = v"7")
end
if any(should_build_platform.(triplet.(platforms_win)))
    build_tarballs(ARGS, name, version, sources, script, platforms_win, products, dependencies; preferred_gcc_version = v"8")
end
if any(should_build_platform.(triplet.(platforms_macos)))
    build_tarballs(ARGS, name, version, sources, script, platforms_macos, products_macos, dependencies)
end
