# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Qt6Declarative"
version = v"6.8.2"

# Set this to true first when updating the version. It will build only for the host (linux musl).
# After that JLL is in the registry, set this to false to build for the other platforms, using
# this same package as host build dependency.
const host_build = false

# Collection of sources required to build qt6
sources = [
    ArchiveSource("https://download.qt.io/official_releases/qt/$(version.major).$(version.minor)/$version/submodules/qtdeclarative-everywhere-src-$version.tar.xz",
                  "144d876adc8bb55909735143e678d1e24eadcd0a380a0186792d88b731346d56"),
    ArchiveSource("https://github.com/roblabla/MacOSX-SDKs/releases/download/macosx14.0/MacOSX14.0.sdk.tar.xz",
                  "4a31565fd2644d1aec23da3829977f83632a20985561a2038e198681e7e7bf49"),
    ArchiveSource("https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v11.0.1.tar.bz2",
                  "3f66bce069ee8bed7439a1a13da7cb91a5e67ea6170f21317ac7f5794625ee10"),
]

script = raw"""
cd $WORKSPACE/srcdir

mkdir build
cd build/
qtsrcdir=`ls -d ../qtdeclarative-*`

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
        apple_sdk_root=$WORKSPACE/srcdir/MacOSX14.0.sdk
        sed -i "s!/opt/$target/$target/sys-root!$apple_sdk_root!" $CMAKE_TARGET_TOOLCHAIN
        sed -i "s!/opt/$target/$target/sys-root!$apple_sdk_root!" /opt/bin/$bb_full_target/$target-clang++
        export MACOSX_DEPLOYMENT_TARGET=12
        export OBJCFLAGS="-D__ENVIRONMENT_OS_VERSION_MIN_REQUIRED__=120000"
        export OBJCXXFLAGS=$OBJCFLAGS
        export CXXFLAGS=$OBJCFLAGS
        cmake -G Ninja -DQT_HOST_PATH=$host_prefix \
        -DPython_ROOT_DIR=/usr \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_PREFIX_PATH=$host_prefix \
        -DCMAKE_FIND_ROOT_PATH=$prefix \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_SYSROOT=$apple_sdk_root -DCMAKE_FRAMEWORK_PATH=$apple_sdk_root/System/Library/Frameworks -DCMAKE_OSX_DEPLOYMENT_TARGET=12 \
        -DQT_NO_APPLE_SDK_AND_XCODE_CHECK=ON \
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
install_license $WORKSPACE/srcdir/qt*-src-*/LICENSES/LGPL-3.0-only.txt
"""

# Get the common Qt platforms
include("../Qt6Base/common.jl")

# The products that we will ensure are always built
products = [
    LibraryProduct(["Qt6LabsAnimation", "libQt6LabsAnimation", "QtLabsAnimation"], :libqt6labsanimation),
    LibraryProduct(["Qt6LabsFolderListModel", "libQt6LabsFolderListModel", "QtLabsFolderListModel"], :libqt6labsfolderlistmodel),
    LibraryProduct(["Qt6LabsQmlModels", "libQt6LabsQmlModels", "QtLabsQmlModels"], :libqt6labsqmlmodels),
    LibraryProduct(["Qt6LabsSettings", "libQt6LabsSettings", "QtLabsSettings"], :libqt6labssettings),
    LibraryProduct(["Qt6LabsSharedImage", "libQt6LabsSharedImage", "QtLabsSharedImage"], :libqt6labssharedimage),
    LibraryProduct(["Qt6LabsWavefrontMesh", "libQt6LabsWavefrontMesh", "QtLabsWavefrontMesh"], :libqt6labswavefrontmesh),
    LibraryProduct(["Qt6Qml", "libQt6Qml", "QtQml"], :libqt6qml),
    LibraryProduct(["Qt6QmlCompiler", "libQt6QmlCompiler", "QtQmlCompiler"], :libqt6qmlcompiler),
    LibraryProduct(["Qt6QmlCore", "libQt6QmlCore", "QtQmlCore"], :libqt6qmlcore),
    LibraryProduct(["Qt6QmlLocalStorage", "libQt6QmlLocalStorage", "QtQmlLocalStorage"], :libqt6qmllocalstorage),
    LibraryProduct(["Qt6QmlModels", "libQt6QmlModels", "QtQmlModels"], :libqt6qmlmodels),
    LibraryProduct(["Qt6QmlNetwork", "libQt6QmlNetwork", "QtQmlNetwork"], :libqt6qmlnetwork),
    LibraryProduct(["Qt6QmlWorkerScript", "libQt6QmlWorkerScript", "QtQmlWorkerScript"], :libqt6qmlworkerscript),
    LibraryProduct(["Qt6QmlXmlListModel", "libQt6QmlXmlListModel", "QtQmlXmlListModel"], :libqt6qmlxmllistmodel),
    LibraryProduct(["Qt6Quick", "libQt6Quick", "QtQuick"], :libqt6quick),
    LibraryProduct(["Qt6QuickControls2", "libQt6QuickControls2", "QtQuickControls2"], :libqt6quickcontrols2),
    LibraryProduct(["Qt6QuickControls2Basic", "libQt6QuickControls2Basic", "QtQuickControls2Basic"], :libqt6quickcontrols2basic),
    LibraryProduct(["Qt6QuickControls2BasicStyleImpl", "libQt6QuickControls2BasicStyleImpl", "QtQuickControls2BasicStyleImpl"], :libqt6quickcontrols2basicstyleimpl),
    LibraryProduct(["Qt6QuickControls2Fusion", "libQt6QuickControls2Fusion", "QtQuickControls2Fusion"], :libqt6quickcontrols2fusion),
    LibraryProduct(["Qt6QuickControls2FusionStyleImpl", "libQt6QuickControls2FusionStyleImpl", "QtQuickControls2FusionStyleImpl"], :libqt6quickcontrols2fusionstyleimpl),
    LibraryProduct(["Qt6QuickControls2Imagine", "libQt6QuickControls2Imagine", "QtQuickControls2Imagine"], :libqt6quickcontrols2imagine),
    LibraryProduct(["Qt6QuickControls2ImagineStyleImpl", "libQt6QuickControls2ImagineStyleImpl", "QtQuickControls2ImagineStyleImpl"], :libqt6quickcontrols2imaginestyleimpl),
    LibraryProduct(["Qt6QuickControls2Impl", "libQt6QuickControls2Impl", "QtQuickControls2Impl"], :libqt6quickcontrols2impl),
    LibraryProduct(["Qt6QuickControls2Material", "libQt6QuickControls2Material", "QtQuickControls2Material"], :libqt6quickcontrols2material),
    LibraryProduct(["Qt6QuickControls2MaterialStyleImpl", "libQt6QuickControls2MaterialStyleImpl", "QtQuickControls2MaterialStyleImpl"], :libqt6quickcontrols2materialstyleimpl),
    LibraryProduct(["Qt6QuickControls2Universal", "libQt6QuickControls2Universal", "QtQuickControls2Universal"], :libqt6quickcontrols2universal),
    LibraryProduct(["Qt6QuickControls2UniversalStyleImpl", "libQt6QuickControls2UniversalStyleImpl", "QtQuickControls2UniversalStyleImpl"], :libqt6quickcontrols2universalstyleimpl),
    LibraryProduct(["Qt6QuickDialogs2", "libQt6QuickDialogs2", "QtQuickDialogs2"], :libqt6quickdialogs2),
    LibraryProduct(["Qt6QuickDialogs2QuickImpl", "libQt6QuickDialogs2QuickImpl", "QtQuickDialogs2QuickImpl"], :libqt6quickdialogs2quickimpl),
    LibraryProduct(["Qt6QuickDialogs2Utils", "libQt6QuickDialogs2Utils", "QtQuickDialogs2Utils"], :libqt6quickdialogs2utils),
    LibraryProduct(["Qt6QuickEffects", "libQt6QuickEffects", "QtQuickEffects"], :libqt6quickeffects),
    LibraryProduct(["Qt6QuickLayouts", "libQt6QuickLayouts", "QtQuickLayouts"], :libqt6quicklayouts),
    LibraryProduct(["Qt6QuickParticles", "libQt6QuickParticles", "QtQuickParticles"], :libqt6quickparticles),
    LibraryProduct(["Qt6QuickShapes", "libQt6QuickShapes", "QtQuickShapes"], :libqt6quickshapes),
    LibraryProduct(["Qt6QuickTemplates2", "libQt6QuickTemplates2", "QtQuickTemplates2"], :libqt6quicktemplates2),
    LibraryProduct(["Qt6QuickTest", "libQt6QuickTest", "QtQuickTest"], :libqt6quicktest),
    LibraryProduct(["Qt6QuickWidgets", "libQt6QuickWidgets", "QtQuickWidgets"], :libqt6quickwidgets),
]

products_win = vcat(products,
    LibraryProduct(["Qt6QuickControls2WindowsStyleImpl", "libQt6QuickControls2WindowsStyleImpl", "QtQuickControls2WindowsStyleImpl"], :libqt6quickcontrols2windowsstyleimpl),
)

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("Qt6Base_jll"),
    HostBuildDependency("Qt6ShaderTools_jll"),
    Dependency("Qt6Base_jll"; compat="="*string(version)),
    Dependency("Qt6ShaderTools_jll"; compat="="*string(version)),
    BuildDependency("Vulkan_Headers_jll"),
]

if !host_build
    push!(dependencies, HostBuildDependency("Qt6Declarative_jll"))
end

build_qt(name, version, sources, script, products, dependencies; products_win)

# rebuild 1