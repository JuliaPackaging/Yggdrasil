# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GR"
version = v"0.53.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sciapp/gr.git", "b490cbfacc6f4dc08c2a2de52c6f6594e8c7c5f9"),
    FileSource("https://github.com/sciapp/gr/releases/download/v$version/gr-$version.js",
               "60b856b8bb834d30612653da42eebef56e4e329d3a73d52c303684ee42b027f1", "gr.js")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gr

if test -f "$prefix/lib/cmake/Qt5Gui/Qt5GuiConfigExtras.cmake"; then
    sed -i 's/_qt5gui_find_extra_libs.*AGL.framework.*//' $prefix/lib/cmake/Qt5Gui/Qt5GuiConfigExtras.cmake
fi

update_configure_scripts

make -C 3rdparty/qhull -j${nproc}

if [[ $target == *"mingw"* ]]; then
    winflags=-DCMAKE_C_FLAGS="-D_WIN32_WINNT=0x0f00"
    tifflags=-DTIFF_LIBRARY=${libdir}/libtiff-5.dll
else
    tifflags=-DTIFF_LIBRARY=${libdir}/libtiff.${dlext}
fi

if [[ "${target}" == *apple* ]]; then
    make -C 3rdparty/zeromq ZEROMQ_EXTRA_CONFIGURE_FLAGS="--host=${target}"
fi

mkdir build
cd build
cmake $winflags -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_FIND_ROOT_PATH=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DGR_USE_BUNDLED_LIBRARIES=ON $tifflags -DCMAKE_BUILD_TYPE=Release ..

VERBOSE=ON cmake --build . --config Release --target install -- -j${nproc}
cp ../../gr.js ${libdir}/

install_license $WORKSPACE/srcdir/gr/LICENSE.md

if [[ $target == *"apple-darwin"* ]]; then
    cd $prefix/lib
    ln -s libGR.so libGR.dylib
    ln -s libGR3.so libGR3.dylib
    ln -s libGRM.so libGRM.dylib
    ln -s libGKS.so libGKS.dylib
    cd ../bin
    ln -s ../Applications/gksqt.app/Contents/MacOS/gksqt ./
    ln -s ../Applications/GKSTerm.app/Contents/MacOS/GKSTerm ./
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("armv7l",  "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64",  "linux"; libc="glibc"),
    Platform("x86_64",  "windows"),
    Platform("x86_64",  "macos"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libGR", :libGR),
    LibraryProduct("libGR3", :libGR3),
    LibraryProduct("libGRM", :libGRM),
    LibraryProduct("libGKS", :libGKS),
    ExecutableProduct("gksqt", :gksqt),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Bzip2_jll"),
    Dependency("Cairo_jll"),
    Dependency("FFMPEG_jll"),
    Dependency("Fontconfig_jll"),
    Dependency("GLFW_jll"),
    Dependency("JpegTurbo_jll"),
    Dependency("libpng_jll"),
    Dependency("Libtiff_jll"),
    Dependency("Pixman_jll"),
    Dependency("Qt_jll"),
    BuildDependency("Xorg_libX11_jll"),
    BuildDependency("Xorg_xproto_jll"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# GCC version 7 because of ffmpeg, but building against Qt requires v8 on Windows.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version = v"8")
