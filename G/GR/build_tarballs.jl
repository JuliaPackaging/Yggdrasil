# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GR"
version = v"0.52.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sciapp/gr.git", "90ee73c741271d964f241f098b0dd3ba18eae271"),
]

# Bash recipe for building across all platforms
script = raw"""
if test -f "$prefix/lib/cmake/Qt5Gui/Qt5GuiConfigExtras.cmake"; then
    sed -i 's/_qt5gui_find_extra_libs.*AGL.framework.*//' $prefix/lib/cmake/Qt5Gui/Qt5GuiConfigExtras.cmake
fi

if [[ $target == *"mingw"* ]]; then
    winflags=-DCMAKE_C_FLAGS="-D_WIN32_WINNT=0x0f00"
fi

mkdir build
cd build
cmake $winflags -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_FIND_ROOT_PATH=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ../gr*
VERBOSE=ON cmake --build . --config Release --target install -- -j${nproc}
install_license $WORKSPACE/srcdir/gr*/LICENSE.md

if [[ $target == *"apple-darwin"* ]]; then
    cd $prefix/lib
    ln -s libGR.so libGR.dylib
    ln -s libGR3.so libGR3.dylib
    ln -s libGRM.so libGRM.dylib
    ln -s libGKS.so libGKS.dylib
    cd ../bin
    ln -s ../Applications/gksqt.app/Contents/MacOS/gksqt ./
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("armv7l", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "windows")
]
platforms = expand_cxxstring_abis(platforms)
push!(platforms, Platform("x86_64", "macos"))

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
    Dependency("Qhull_jll"),
    Dependency("Qt_jll"),
    BuildDependency("Xorg_libX11_jll"),
    BuildDependency("Xorg_xproto_jll"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# GCC version 7 because of ffmpeg, but building against Qt requires v8 on Windows.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8")
