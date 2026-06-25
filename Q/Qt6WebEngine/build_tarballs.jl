# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Qt6WebEngine"
version = v"6.5.2"

# Collection of sources required to build qt6
sources = [
    ArchiveSource("https://download.qt.io/official_releases/qt/$(version.major).$(version.minor)/$version/submodules/qtwebengine-everywhere-src-$version.tar.xz",
                  "e7c9438b56f502b44b4e376b92ed80f1db7c2c3881d68d319b0677afd5701d9f"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/11.0-11.1/MacOSX11.1.sdk.tar.xz",
                  "9b86eab03176c56bb526de30daa50fa819937c54b280364784ce431885341bf6"),
    ArchiveSource("https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v10.0.0.tar.bz2",
                  "ba6b430aed72c63a3768531f6a3ffc2b0fde2c57a3b251450dcf489a894f0894"),
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir

wget https://unofficial-builds.nodejs.org/download/release/v21.6.2/node-v21.6.2-linux-x64-musl.tar.gz
tar xf node-v21.6.2-linux-x64-musl.tar.gz
cp -r node-v21.6.2*/* ${host_prefix}/.

mkdir -p qtwebengine-everywhere-src-6.5.2/src/3rdparty/chromium/build/mac_files/xcode_binaries/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs
ln -s $WORKSPACE/srcdir/MacOSX11.1.sdk qtwebengine-everywhere-src-6.5.2/src/3rdparty/chromium/build/mac_files/xcode_binaries/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX12.3.sdk

mkdir build
cd build/
qtsrcdir=`ls -d ../qtwebengine-*`

atomic_patch -p1 -d "${qtsrcdir}" ../patches/webengine.patch

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
        cmake -DQT_HOST_PATH=$host_prefix \
            -DPython_ROOT_DIR=/usr \
            -DCMAKE_INSTALL_PREFIX=${prefix} \
            -DCMAKE_PREFIX_PATH=$host_prefix \
            -DCMAKE_FIND_ROOT_PATH=$prefix \
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
            -DCMAKE_BUILD_TYPE=Release \
        $qtsrcdir
    ;;

    *apple-darwin*)
        apple_sdk_root=$WORKSPACE/srcdir/MacOSX11.1.sdk
        sed -i "s!/opt/x86_64-apple-darwin14/x86_64-apple-darwin14/sys-root!$apple_sdk_root!" $CMAKE_TARGET_TOOLCHAIN
        deployarg="-DCMAKE_OSX_DEPLOYMENT_TARGET=10.14"
        cmake -DQT_HOST_PATH=$host_prefix \
        -DPython_ROOT_DIR=/usr \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_PREFIX_PATH=$host_prefix \
        -DCMAKE_FIND_ROOT_PATH=$prefix \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_SYSROOT=$apple_sdk_root -DCMAKE_FRAMEWORK_PATH=$apple_sdk_root/System/Library/Frameworks -DCMAKE_OSX_DEPLOYMENT_TARGET=10.15 \
        -DCMAKE_CXX_COMPILER_ID=AppleClang -DCMAKE_CXX_COMPILER_VERSION=10.0.0 -DCMAKE_CXX_STANDARD_COMPUTED_DEFAULT=11 \
        -DCMAKE_BUILD_TYPE=Release \
        $qtsrcdir
    ;;

    *)
        cmake -DQT_HOST_PATH=$host_prefix \
        -DPython_ROOT_DIR=/usr \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_PREFIX_PATH=$host_prefix \
        -DCMAKE_FIND_ROOT_PATH=$prefix \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_BUILD_TYPE=Release \
        $qtsrcdir
    ;;

esac

cmake --build . --parallel ${nproc}
cmake --install .
install_license $WORKSPACE/srcdir/qt*-src-*/LICENSES/LGPL-3.0-only.txt__
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(filter(!Sys.isapple, supported_platforms()))
filter!(p -> arch(p) != "armv6l", platforms) # No OpenGL on armv6
platforms_macos = [ Platform("x86_64", "macos"), Platform("aarch64", "macos") ]

# The products that we will ensure are always built
products = [
    LibraryProduct(["Qt6Pdf", "libQt6Pdf", "QtPdf"], :libqt6pdf),
    LibraryProduct(["Qt6PdfQuick", "libQt6PdfQuick", "QtPdfQuick"], :libqt6pdfquick),
    LibraryProduct(["Qt6PdfWidgets", "libQt6PdfWidgets", "QtPdfWidgets"], :libqt6pdfwidgets),
    LibraryProduct(["Qt6WebEngineCore", "libQt6WebEngineCore", "QtWebEngineCore"], :libqt6webenginecore),
    LibraryProduct(["Qt6WebEngineQuick", "libQt6WebEngineQuick", "QtWebEngineQuick"], :libqt6webenginequick),
    LibraryProduct(["Qt6WebEngineQuickDelegatesQml", "libQt6WebEngineQuickDelegatesQml", "QtWebEngineQuickDelegatesQml"], :libqt6webenginequickdelegatesqml),
    LibraryProduct(["Qt6WebEngineWidgets", "libQt6WebEngineWidgets", "QtWebEngineWidgets"], :libqt6webenginewidgets),
]

products_macos = [
    FrameworkProduct("QtPdf", :libqt6pdf),
    FrameworkProduct("QtPdfQuick", :libqt6pdfquick),
    FrameworkProduct("QtPdfWidgets", :libqt6pdfwidgets),
    FrameworkProduct("QtWebEngineCore", :libqt6webenginecore),
    FrameworkProduct("QtWebEngineQuick", :libqt6webenginequick),
    FrameworkProduct("QtWebEngineQuickDelegatesQml", :libqt6webenginequickdelegatesqml),
    FrameworkProduct("QtWebEngineWidgets", :libqt6webenginewidgets),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("Qt6Base_jll"),
    HostBuildDependency("Qt6Declarative_jll"),
    HostBuildDependency("NodeJS_20_jll"),
    Dependency("Qt6Base_jll"; compat="="*string(version)),
    Dependency("Qt6Declarative_jll"; compat="="*string(version)),
    Dependency("Qt6Positioning_jll"; compat="="*string(version)),
    Dependency("Qt6WebSockets_jll"; compat="="*string(version)),
    Dependency("Qt6WebChannel_jll"; compat="="*string(version)),
]

include("../../fancy_toys.jl")

if any(should_build_platform.(triplet.(platforms_macos)))
    build_tarballs(ARGS, name, version, sources, script, platforms_macos, products_macos, dependencies; preferred_gcc_version = v"10", julia_compat="1.6")
end

if any(should_build_platform.(triplet.(platforms)))
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"10", julia_compat="1.6")
end
