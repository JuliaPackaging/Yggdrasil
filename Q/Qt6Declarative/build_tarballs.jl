# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Qt6Declarative"
version = v"6.4.2"

# Set this to true first when updating the version. It will build only for the host (linux musl).
# After that JLL is in the registyry, set this to false to build for the other platforms, using
# this same package as host build dependency.
const host_build = false

# Collection of sources required to build qt6
sources = [
    ArchiveSource("https://download.qt.io/official_releases/qt/$(version.major).$(version.minor)/$version/submodules/qtdeclarative-everywhere-src-$version.tar.xz",
                  "a4bdd983de4e9cbca0f85b767dbdd8598711554e370a06da8f509ded4430f5bd"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/11.0-11.1/MacOSX11.1.sdk.tar.xz",
                  "9b86eab03176c56bb526de30daa50fa819937c54b280364784ce431885341bf6"),
    ArchiveSource("https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v10.0.0.tar.bz2",
                  "ba6b430aed72c63a3768531f6a3ffc2b0fde2c57a3b251450dcf489a894f0894")
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
        apple_sdk_root=$WORKSPACE/srcdir/MacOSX11.1.sdk
        sed -i "s!/opt/x86_64-apple-darwin14/x86_64-apple-darwin14/sys-root!$apple_sdk_root!" $CMAKE_TARGET_TOOLCHAIN
        cmake -DQT_HOST_PATH=$host_prefix \
        -DPython_ROOT_DIR=/usr \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_PREFIX_PATH=$host_prefix \
        -DCMAKE_FIND_ROOT_PATH=$prefix \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_SYSROOT=$apple_sdk_root -DCMAKE_FRAMEWORK_PATH=$apple_sdk_root/System/Library/Frameworks -DCMAKE_OSX_DEPLOYMENT_TARGET=10.15 \
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
    LibraryProduct(["Qt6Qml", "libQt6Qml", "QtQml"], :libqt6qml),
    LibraryProduct(["Qt6QmlModels", "libQt6QmlModels", "QtQmlModels"], :libqt6qmlmodels),
    LibraryProduct(["Qt6QmlCore", "libQt6QmlCore", "QtQmlCore"], :libqt6qmlcore),
    LibraryProduct(["Qt6QmlWorkerScript", "libQt6QmlWorkerScript", "QtQmlWorkerScript"], :libqt6qmlworkerscript),
    LibraryProduct(["Qt6QmlLocalStorage", "libQt6QmlLocalStorage", "QtQmlLocalStorage"], :libqt6qmllocalstorage),
    LibraryProduct(["Qt6QmlXmlListModel", "libQt6QmlXmlListModel", "QtQmlXmlListModel"], :libqt6qmlxmllistmodel),
    LibraryProduct(["Qt6Quick", "libQt6Quick", "QtQuick"], :libqt6quick),
    LibraryProduct(["Qt6QuickLayouts", "libQt6QuickLayouts", "QtQuickLayouts"], :libqt6quicklayouts),
    LibraryProduct(["Qt6QuickTest", "libQt6QuickTest", "QtQuickTest"], :libqt6quicktest),
    LibraryProduct(["Qt6QuickParticles", "libQt6QuickParticles", "QtQuickParticles"], :libqt6quickparticles),
    LibraryProduct(["Qt6QuickShapes", "libQt6QuickShapes", "QtQuickShapes"], :libqt6quickshapes),
    LibraryProduct(["Qt6QuickWidgets", "libQt6QuickWidgets", "QtQuickWidgets"], :libqt6quickwidgets),
    LibraryProduct(["Qt6QuickTemplates2", "libQt6QuickTemplates2", "QtQuickTemplates2"], :libqt6quicktemplates2),
    LibraryProduct(["Qt6QuickControls2Impl", "libQt6QuickControls2Impl", "QtQuickControls2Impl"], :libqt6quickcontrols2impl),
    LibraryProduct(["Qt6QuickControls2", "libQt6QuickControls2", "QtQuickControls2"], :libqt6quickcontrols2),
    LibraryProduct(["Qt6QuickDialogs2Utils", "libQt6QuickDialogs2Utils", "QtQuickDialogs2Utils"], :libqt6quickdialogs2utils),
    LibraryProduct(["Qt6QuickDialogs2QuickImpl", "libQt6QuickDialogs2QuickImpl", "QtQuickDialogs2QuickImpl"], :libqt6quickdialogs2quickimpl),
    LibraryProduct(["Qt6QuickDialogs2", "libQt6QuickDialogs2", "QtQuickDialogs2"], :libqt6quickdialogs2),
    LibraryProduct(["Qt6LabsSettings", "libQt6LabsSettings", "QtLabsSettings"], :libqt6labssettings),
    LibraryProduct(["Qt6LabsQmlModels", "libQt6LabsQmlModels", "QtLabsQmlModels"], :libqt6labsqmlmodels),
    LibraryProduct(["Qt6LabsFolderListModel", "libQt6LabsFolderListModel", "QtLabsFolderListModel"], :libqt6labsfolderlistmodel),
    LibraryProduct(["Qt6LabsAnimation", "libQt6LabsAnimation", "QtLabsAnimation"], :libqt6labsanimation),
    LibraryProduct(["Qt6LabsWavefrontMesh", "libQt6LabsWavefrontMesh", "QtLabsWavefrontMesh"], :libqt6labswavefrontmesh),
    LibraryProduct(["Qt6LabsSharedImage", "libQt6LabsSharedImage", "QtLabsSharedImage"], :libqt6labssharedimage),
]

products_macos = [
    FrameworkProduct("QtQml", :libqt6qml),
    FrameworkProduct("QtQmlModels", :libqt6qmlmodels),
    FrameworkProduct("QtQmlCore", :libqt6qmlcore),
    FrameworkProduct("QtQmlWorkerScript", :libqt6qmlworkerscript),
    FrameworkProduct("QtQmlLocalStorage", :libqt6qmllocalstorage),
    FrameworkProduct("QtQmlXmlListModel", :libqt6qmlxmllistmodel),
    FrameworkProduct("QtQuick", :libqt6quick),
    FrameworkProduct("QtQuickLayouts", :libqt6quicklayouts),
    FrameworkProduct("QtQuickTest", :libqt6quicktest),
    FrameworkProduct("QtQuickParticles", :libqt6quickparticles),
    FrameworkProduct("QtQuickShapes", :libqt6quickshapes),
    FrameworkProduct("QtQuickWidgets", :libqt6quickwidgets),
    FrameworkProduct("QtQuickTemplates2", :libqt6quicktemplates2),
    FrameworkProduct("QtQuickControls2Impl", :libqt6quickcontrols2impl),
    FrameworkProduct("QtQuickControls2", :libqt6quickcontrols2),
    FrameworkProduct("QtQuickDialogs2Utils", :libqt6quickdialogs2utils),
    FrameworkProduct("QtQuickDialogs2QuickImpl", :libqt6quickdialogs2quickimpl),
    FrameworkProduct("QtQuickDialogs2", :libqt6quickdialogs2),
    FrameworkProduct("QtLabsSettings", :libqt6labssettings),
    FrameworkProduct("QtLabsQmlModels", :libqt6labsqmlmodels),
    FrameworkProduct("QtLabsFolderListModel", :libqt6labsfolderlistmodel),
    FrameworkProduct("QtLabsAnimation", :libqt6labsanimation),
    FrameworkProduct("QtLabsWavefrontMesh", :libqt6labswavefrontmesh),
    FrameworkProduct("QtLabsSharedImage", :libqt6labssharedimage),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("Qt6Base_jll"),
    HostBuildDependency("Qt6ShaderTools_jll"),
    Dependency("Qt6Base_jll"; compat="="*string(version)),
    Dependency("Qt6ShaderTools_jll"; compat="="*string(version)),
]

if !host_build
    push!(dependencies, HostBuildDependency("Qt6Declarative_jll"))
end

include("../../fancy_toys.jl")

@static if !host_build
    if any(should_build_platform.(triplet.(platforms_macos)))
        build_tarballs(ARGS, name, version, sources, script, platforms_macos, products_macos, dependencies; preferred_gcc_version = v"9", julia_compat="1.6")
    end
end
if any(should_build_platform.(triplet.(platforms)))
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"9", julia_compat="1.6")
end
