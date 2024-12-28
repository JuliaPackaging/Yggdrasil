# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Qt5Base"
version = v"5.15.3"

# Collection of sources required to build qt5
sources = [
    ArchiveSource("https://download.qt.io/official_releases/qt/$(version.major).$(version.minor)/$(version)/submodules/qtbase-everywhere-opensource-src-$(version).tar.xz",
                  "26394ec9375d52c1592bd7b689b1619c6b8dbe9b6f91fdd5c355589787f3a0b6"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.14.sdk.tar.xz",
                  "0f03869f72df8705b832910517b47dd5b79eb4e160512602f593ed243b28715f"),
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir

BIN_DIR="/opt/bin/${bb_full_target}"

mkdir build
cd build/

qtsrcdir=`ls -d ../qtbase-everywhere-src-*`
atomic_patch -p1 -d "${qtsrcdir}" ../patches/0001-gcc-11.patch
atomic_patch -p1 -d "${qtsrcdir}" ../patches/0003-gcc-11.patch

commonoptions=" \
-opensource -confirm-license \
-openssl-linked  -nomake examples -release \
"

export OPENSSL_LIBS="-L${libdir} -lssl -lcrypto"

cp -a ../qtbase-everywhere-src-*/mkspecs/linux-aarch64-gnu-g++ $qtsrcdir/mkspecs/musl
sed -i 's/aarch64-linux-gnu/x86_64-linux-musl/g' ../qtbase-everywhere-src-*/mkspecs/musl/qmake.conf

cp -a ../qtbase-everywhere-src-*/mkspecs/linux-aarch64-gnu-g++ $qtsrcdir/mkspecs/$target
sed -i "s/aarch64-linux-gnu/$target/g" ../qtbase-everywhere-src-*/mkspecs/$target/qmake.conf
echo "QMAKE_CFLAGS_ARCH_HASWELL =" >> ../qtbase-everywhere-src-*/mkspecs/$target/qmake.conf

case "$target" in

	*linux*)
        ../qtbase-everywhere-src-*/configure -L ${libdir} -I ${includedir} \
            -platform musl -xplatform $target -device-option CROSS_COMPILE=${BIN_DIR}/$target- \
            -prefix $prefix $commonoptions \
            -fontconfig
        ;;

	*apple-darwin*)
        echo "QMAKE_CFLAGS_ARCH_HASWELL =" >> ../qtbase-everywhere-src-*/mkspecs/macx-clang/qmake.conf
        if [[ "${target}" == x86_64-* ]]; then
            cd $WORKSPACE/srcdir/MacOSX10.14.sdk
            rm -rf /opt/$target/$target/sys-root/System
            rsync -a usr/* /opt/$target/$target/sys-root/usr/
            cp -a System /opt/$target/$target/sys-root/
            export MACOSX_DEPLOYMENT_TARGET=10.13
            # Link to libclang_rt.osx to resolve the symbol `___isPlatformVersionAtLeast`.
            rtlibdir="-L${libdir}/darwin"
            rtlibs="QMAKE_LFLAGS+=-lclang_rt.osx"
        fi

        cd $WORKSPACE/srcdir/qtbase-everywhere-src-*/

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

        for bin in "${BIN_DIR}/clang++" "${BIN_DIR}/clang"; do
            sed -i "s?-fuse-ld=[^ ]\+?-fuse-ld=${BIN_DIR}/ld?g" "${bin}"
        done

        cd $WORKSPACE/srcdir/build

        if [[ "${target}" == aarch64-* ]]; then
            CONFIGURE_EXTRA_FLAGS=(-device-option QMAKE_APPLE_DEVICE_ARCHS=arm64)
            sed -i 's/QMAKE_APPLE_DEVICE_ARCHS = .*/QMAKE_APPLE_DEVICE_ARCHS = arm64/' ../qtbase-everywhere-src-*/mkspecs/common/macx.conf
        fi

        export QT_MAC_SDK_NO_VERSION_CHECK=1
        ../qtbase-everywhere-src-*/configure \
            QMAKE_CXXFLAGS+=-F/opt/$target/$target/sys-root/System/Library/Frameworks $rtlibdir $rtlibs \
            QMAKE_RANLIB=${BIN_DIR}/ranlib \
            QMAKE_MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}" \
            -platform musl -xplatform macx-clang -device-option CROSS_COMPILE=${BIN_DIR}/$target- \
            -prefix ${prefix} $commonoptions \
            -skip qtwinextras \
            "${CONFIGURE_EXTRA_FLAGS[@]}"
        ;;

    *mingw*)
        echo "QMAKE_CFLAGS_ARCH_HASWELL =" >> ../qtbase-everywhere-src-*/mkspecs/win32-g++/qmake.conf
        ../qtbase-everywhere-src-*/configure -I $WORKSPACE/srcdir/qtbase-everywhere-src-*/include/QtANGLE -platform musl -xplatform win32-g++ -device-option CROSS_COMPILE=${BIN_DIR}/$target- \
            -prefix $prefix $commonoptions \
            -opengl dynamic
		;;

    *x86_64-unknown-freebsd*)
        sed -i 's/load(qt_config)//' ../qtbase-everywhere-src-*/mkspecs/freebsd-g++/qmake.conf
        grep -A11 QMAKE_CC ../qtbase-everywhere-src-*/mkspecs/linux-aarch64-gnu-g++/qmake.conf | sed -e 's/aarch64-linux-gnu-//' >> ../qtbase-everywhere-src-*/mkspecs/freebsd-g++/qmake.conf
        echo "QMAKE_CFLAGS_ARCH_HASWELL =" >> ../qtbase-everywhere-src-*/mkspecs/freebsd-g++/qmake.conf

        ../qtbase-everywhere-src-*/configure -platform musl -xplatform freebsd-g++ -device-option CROSS_COMPILE=${BIN_DIR}/$target- \
            -extprefix $prefix $commonoptions \
            -skip qtwinextras -fontconfig -sysroot /opt/$target/bin/../$target/sys-root
		;;
esac

make -j${nproc}
make install
$BUILD_STRIP $bindir/qmake
install_license $WORKSPACE/srcdir/qtbase-everywhere-src-*/LICENSE.LGPLv3
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms_linux = [
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("armv7l", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "freebsd"),
    Platform("powerpc64le", "linux"; libc="glibc"),
]
platforms_linux = expand_cxxstring_abis(platforms_linux)
platforms_win = expand_cxxstring_abis([Platform("x86_64", "windows"), Platform("i686", "windows")])
platforms_macos = [ Platform("x86_64", "macos"), Platform("aarch64", "macos") ]

# The products that we will ensure are always built
products = [
    LibraryProduct(["Qt5Concurrent", "libQt5Concurrent", "QtConcurrent"], :libqt5concurrent),
    LibraryProduct(["Qt5Core", "libQt5Core", "QtCore"], :libqt5core),
    LibraryProduct(["Qt5DBus", "libQt5DBus", "QtDBus"], :libqt5dbus),
    LibraryProduct(["Qt5Gui", "libQt5Gui", "QtGui"], :libqt5gui),
    LibraryProduct(["Qt5Network", "libQt5Network", "QtNetwork"], :libqt5network),
    LibraryProduct(["Qt5OpenGL", "libQt5OpenGL", "QtOpenGL"], :libqt5opengl),
    LibraryProduct(["Qt5PrintSupport", "libQt5PrintSupport", "QtPrintSupport"], :libqt5printsupport),
    LibraryProduct(["Qt5Sql", "libQt5Sql", "QtSql"], :libqt5sql),
    LibraryProduct(["Qt5Test", "libQt5Test", "QtTest"], :libqt5test),
    LibraryProduct(["Qt5Widgets", "libQt5Widgets", "QtWidgets"], :libqt5widgets),
    LibraryProduct(["Qt5Xml", "libQt5Xml", "QtXml"], :libqt5xml),
]

products_macos = [
    FrameworkProduct("QtConcurrent", :libqt5concurrent),
    FrameworkProduct("QtCore", :libqt5core),
    FrameworkProduct("QtDBus", :libqt5dbus),
    FrameworkProduct("QtGui", :libqt5gui),
    FrameworkProduct("QtNetwork", :libqt5network),
    FrameworkProduct("QtOpenGL", :libqt5opengl),
    FrameworkProduct("QtPrintSupport", :libqt5printsupport),
    FrameworkProduct("QtSql", :libqt5sql),
    FrameworkProduct("QtTest", :libqt5test),
    FrameworkProduct("QtWidgets", :libqt5widgets),
    FrameworkProduct("QtXml", :libqt5xml),
]

# We must use the same version of LLVM for the build toolchain and LLVMCompilerRT_jll
llvm_version = v"13.0.1"

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_libX11_jll"; platforms=platforms_linux),
    Dependency("Xorg_libXext_jll"; platforms=platforms_linux),
    BuildDependency("Xorg_glproto_jll"; platforms=platforms_linux),
    Dependency("Xorg_libxcb_jll"; platforms=platforms_linux),
    Dependency("Xorg_xcb_util_wm_jll"; platforms=platforms_linux),
    Dependency("Xorg_xcb_util_image_jll"; platforms=platforms_linux),
    Dependency("Xorg_xcb_util_keysyms_jll"; platforms=platforms_linux),
    Dependency("Xorg_xcb_util_renderutil_jll"; platforms=platforms_linux),
    Dependency("xkbcommon_jll"; platforms=platforms_linux),
    Dependency("Libglvnd_jll"; platforms=platforms_linux),
    Dependency("Fontconfig_jll"),
    Dependency("Glib_jll"; compat="2.68.1"),
    Dependency("Zlib_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("OpenSSL_jll"; compat="1.1.10"),
    BuildDependency(PackageSpec(name="LLVMCompilerRT_jll", uuid="4e17d02c-6bf5-513e-be62-445f41c75a11", version=llvm_version);
                    platforms=filter(p -> Sys.isapple(p) && arch(p) == "x86_64", platforms_macos)),
]

include("../../fancy_toys.jl")

julia_compat = "1.6"

if any(should_build_platform.(triplet.(platforms_linux)))
    build_tarballs(ARGS, name, version, sources, script, platforms_linux, products, dependencies; preferred_gcc_version = v"7", preferred_llvm_version=llvm_version, julia_compat)
end
if any(should_build_platform.(triplet.(platforms_win)))
    build_tarballs(ARGS, name, version, sources, script, platforms_win, products, dependencies; preferred_gcc_version = v"8", preferred_llvm_version=llvm_version, julia_compat)
end
if any(should_build_platform.(triplet.(platforms_macos)))
    build_tarballs(ARGS, name, version, sources, script, platforms_macos, products_macos, dependencies; preferred_gcc_version = v"7", preferred_llvm_version=llvm_version, julia_compat)
end
