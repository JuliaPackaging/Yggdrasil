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
        
        ../qt-everywhere-src-*/configure -I $WORKSPACE/srcdir/qt-everywhere-src-*/qtbase/include/QtANGLE -platform linux-g++ -xplatform win32-g++ -device-option CROSS_COMPILE=/opt/bin/$target- \
            -prefix $prefix $commonoptions \
            -opengl dynamic
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
    Platform("armv7l", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
]
platforms_linux = expand_cxxstring_abis(platforms_linux)
platforms_win = expand_cxxstring_abis([Platform("x86_64", "windows")])
platforms_macos = [ Platform("x86_64", "macos") ]

# The products that we will ensure are always built
products = [
    LibraryProduct(["Qt53DAnimation", "libQt53DAnimation", "Qt3DAnimation"], :libqt53danimation),
    LibraryProduct(["Qt53DCore", "libQt53DCore", "Qt3DCore"], :libqt53dcore),
    LibraryProduct(["Qt53DExtras", "libQt53DExtras", "Qt3DExtras"], :libqt53dextras),
    LibraryProduct(["Qt53DInput", "libQt53DInput", "Qt3DInput"], :libqt53dinput),
    LibraryProduct(["Qt53DLogic", "libQt53DLogic", "Qt3DLogic"], :libqt53dlogic),
    LibraryProduct(["Qt53DQuick", "libQt53DQuick", "Qt3DQuick"], :libqt53dquick),
    LibraryProduct(["Qt53DQuickAnimation", "libQt53DQuickAnimation", "Qt3DQuickAnimation"], :libqt53dquickanimation),
    LibraryProduct(["Qt53DQuickExtras", "libQt53DQuickExtras", "Qt3DQuickExtras"], :libqt53dquickextras),
    LibraryProduct(["Qt53DQuickInput", "libQt53DQuickInput", "Qt3DQuickInput"], :libqt53dquickinput),
    LibraryProduct(["Qt53DQuickRender", "libQt53DQuickRender", "Qt3DQuickRender"], :libqt53dquickrender),
    LibraryProduct(["Qt53DQuickScene2D", "libQt53DQuickScene2D", "Qt3DQuickScene2D"], :libqt53dquickscene2d),
    LibraryProduct(["Qt53DRender", "libQt53DRender", "Qt3DRender"], :libqt53drender),
    LibraryProduct(["Qt5Bodymovin", "libQt5Bodymovin", "QtBodymovin"], :libqt5bodymovin),
    LibraryProduct(["Qt5Charts", "libQt5Charts", "QtCharts"], :libqt5charts),
    LibraryProduct(["Qt5Concurrent", "libQt5Concurrent", "QtConcurrent"], :libqt5concurrent),
    LibraryProduct(["Qt5Core", "libQt5Core", "QtCore"], :libqt5core),
    LibraryProduct(["Qt5DBus", "libQt5DBus", "QtDBus"], :libqt5dbus),
    LibraryProduct(["Qt5Gui", "libQt5Gui", "QtGui"], :libqt5gui),
    LibraryProduct(["Qt5Multimedia", "libQt5Multimedia", "QtMultimedia"], :libqt5multimedia),
    LibraryProduct(["Qt5MultimediaQuick", "libQt5MultimediaQuick", "QtMultimediaQuick"], :libqt5multimediaquick),
    LibraryProduct(["Qt5MultimediaWidgets", "libQt5MultimediaWidgets", "QtMultimediaWidgets"], :libqt5multimediawidgets),
    LibraryProduct(["Qt5Network", "libQt5Network", "QtNetwork"], :libqt5network),
    LibraryProduct(["Qt5OpenGL", "libQt5OpenGL", "QtOpenGL"], :libqt5opengl),
    LibraryProduct(["Qt5PrintSupport", "libQt5PrintSupport", "QtPrintSupport"], :libqt5printsupport),
    LibraryProduct(["Qt5Qml", "libQt5Qml", "QtQml"], :libqt5qml),
    LibraryProduct(["Qt5QmlModels", "libQt5QmlModels", "QtQmlModels"], :libqt5qmlmodels),
    LibraryProduct(["Qt5QmlWorkerScript", "libQt5QmlWorkerScript", "QtQmlWorkerScript"], :libqt5qmlworkerscript),
    LibraryProduct(["Qt5Quick", "libQt5Quick", "QtQuick"], :libqt5quick),
    LibraryProduct(["Qt5Quick3D", "libQt5Quick3D", "QtQuick3D"], :libqt5quick3d),
    LibraryProduct(["Qt5Quick3DAssetImport", "libQt5Quick3DAssetImport", "QtQuick3DAssetImport"], :libqt5quick3dassetimport),
    LibraryProduct(["Qt5Quick3DRender", "libQt5Quick3DRender", "QtQuick3DRender"], :libqt5quick3drender),
    LibraryProduct(["Qt5Quick3DRuntimeRender", "libQt5Quick3DRuntimeRender", "QtQuick3DRuntimeRender"], :libqt5quick3druntimerender),
    LibraryProduct(["Qt5Quick3DUtils", "libQt5Quick3DUtils", "QtQuick3DUtils"], :libqt5quick3dutils),
    LibraryProduct(["Qt5QuickControls2", "libQt5QuickControls2", "QtQuickControls2"], :libqt5quickcontrols2),
    LibraryProduct(["Qt5QuickParticles", "libQt5QuickParticles", "QtQuickParticles"], :libqt5quickparticles),
    LibraryProduct(["Qt5QuickShapes", "libQt5QuickShapes", "QtQuickShapes"], :libqt5quickshapes),
    LibraryProduct(["Qt5QuickTemplates2", "libQt5QuickTemplates2", "QtQuickTemplates2"], :libqt5quicktemplates2),
    LibraryProduct(["Qt5QuickTest", "libQt5QuickTest", "QtQuickTest"], :libqt5quicktest),
    LibraryProduct(["Qt5QuickWidgets", "libQt5QuickWidgets", "QtQuickWidgets"], :libqt5quickwidgets),
    LibraryProduct(["Qt5Sql", "libQt5Sql", "QtSql"], :libqt5sql),
    LibraryProduct(["Qt5Svg", "libQt5Svg", "QtSvg"], :libqt5svg),
    LibraryProduct(["Qt5Test", "libQt5Test", "QtTest"], :libqt5test),
    LibraryProduct(["Qt5Widgets", "libQt5Widgets", "QtWidgets"], :libqt5widgets),
    LibraryProduct(["Qt5Xml", "libQt5Xml", "QtXml"], :libqt5xml),
    LibraryProduct(["Qt5XmlPatterns", "libQt5XmlPatterns", "QtXmlPatterns"], :libqt5xmlpatterns),
]

products_macos = [
    FrameworkProduct("Qt3DAnimation", :libqt53danimation),
    FrameworkProduct("Qt3DCore", :libqt53dcore),
    FrameworkProduct("Qt3DExtras", :libqt53dextras),
    FrameworkProduct("Qt3DInput", :libqt53dinput),
    FrameworkProduct("Qt3DLogic", :libqt53dlogic),
    FrameworkProduct("Qt3DQuick", :libqt53dquick),
    FrameworkProduct("Qt3DQuickAnimation", :libqt53dquickanimation),
    FrameworkProduct("Qt3DQuickExtras", :libqt53dquickextras),
    FrameworkProduct("Qt3DQuickInput", :libqt53dquickinput),
    FrameworkProduct("Qt3DQuickRender", :libqt53dquickrender),
    FrameworkProduct("Qt3DQuickScene2D", :libqt53dquickscene2d),
    FrameworkProduct("Qt3DRender", :libqt53drender),
    FrameworkProduct("QtBodymovin", :libqt5bodymovin),
    FrameworkProduct("QtCharts", :libqt5charts),
    FrameworkProduct("QtConcurrent", :libqt5concurrent),
    FrameworkProduct("QtCore", :libqt5core),
    FrameworkProduct("QtDBus", :libqt5dbus),
    FrameworkProduct("QtGui", :libqt5gui),
    FrameworkProduct("QtMultimedia", :libqt5multimedia),
    FrameworkProduct("QtMultimediaQuick", :libqt5multimediaquick),
    FrameworkProduct("QtMultimediaWidgets", :libqt5multimediawidgets),
    FrameworkProduct("QtNetwork", :libqt5network),
    FrameworkProduct("QtOpenGL", :libqt5opengl),
    FrameworkProduct("QtPrintSupport", :libqt5printsupport),
    FrameworkProduct("QtQml", :libqt5qml),
    FrameworkProduct("QtQmlModels", :libqt5qmlmodels),
    FrameworkProduct("QtQmlWorkerScript", :libqt5qmlworkerscript),
    FrameworkProduct("QtQuick", :libqt5quick),
    FrameworkProduct("QtQuick3D", :libqt5quick3d),
    FrameworkProduct("QtQuick3DAssetImport", :libqt5quick3dassetimport),
    FrameworkProduct("QtQuick3DRender", :libqt5quick3drender),
    FrameworkProduct("QtQuick3DRuntimeRender", :libqt5quick3druntimerender),
    FrameworkProduct("QtQuick3DUtils", :libqt5quick3dutils),
    FrameworkProduct("QtQuickControls2", :libqt5quickcontrols2),
    FrameworkProduct("QtQuickParticles", :libqt5quickparticles),
    FrameworkProduct("QtQuickShapes", :libqt5quickshapes),
    FrameworkProduct("QtQuickTemplates2", :libqt5quicktemplates2),
    FrameworkProduct("QtQuickTest", :libqt5quicktest),
    FrameworkProduct("QtQuickWidgets", :libqt5quickwidgets),
    FrameworkProduct("QtSql", :libqt5sql),
    FrameworkProduct("QtSvg", :libqt5svg),
    FrameworkProduct("QtTest", :libqt5test),
    FrameworkProduct("QtWidgets", :libqt5widgets),
    FrameworkProduct("QtXml", :libqt5xml),
    FrameworkProduct("QtXmlPatterns", :libqt5xmlpatterns),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_libX11_jll"),
    Dependency("Xorg_libXext_jll"),
    BuildDependency("Xorg_glproto_jll"),
    Dependency("Xorg_libxcb_jll"),
    Dependency("Xorg_xcb_util_wm_jll"),
    Dependency("Xorg_xcb_util_image_jll"),
    Dependency("Xorg_xcb_util_keysyms_jll"),
    Dependency("Xorg_xcb_util_renderutil_jll"),
    Dependency("xkbcommon_jll"),
    BuildDependency("Libglvnd_jll"),
    Dependency("Fontconfig_jll"),
    Dependency("Glib_jll"),
    Dependency("Zlib_jll"),
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
