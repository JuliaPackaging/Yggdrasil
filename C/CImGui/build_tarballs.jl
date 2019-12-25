# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CImGui"
version = v"1.74.0"

# Collection of sources required to build CImGui
sources = [
    "https://github.com/ocornut/imgui.git" =>
    "bdce8336364595d1a446957a6164c97363349a53",

    "https://github.com/cimgui/cimgui.git" =>
    "d9e1d9a80d621cd96d9900ac340092853100416f",

    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mv imgui cimgui/
mv wrapper/helper.c cimgui/
mv wrapper/helper.h cimgui/
cd cimgui/
rm CMakeLists.txt
mv ../wrapper/CMakeLists.txt ./
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcimgui", :libcimgui)
    LibraryProduct("libcimgui_helper", :libcimgui_helper)
]

# Dependencies that must be installed before this package can be built
dependencies = [

]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
