# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CImGui"
version = v"1.75.0"

# Collection of sources required to build CImGui
sources = [
    GitSource("https://github.com/ocornut/imgui.git",
              "58b3e02b95b4c7c5bb9128a28c6d55546501bf93"),

    GitSource("https://github.com/cimgui/cimgui.git",
              "c5eea0b2dbfb2fc763292c410aba69a72eccfc4f"),

    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
rm cimgui/CMakeLists.txt
mv imgui wrapper/helper.c wrapper/helper.h wrapper/CMakeLists.txt cimgui/
mkdir -p cimgui/build && cd cimgui/build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
install_license ../LICENSE ../imgui/LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcimgui", :libcimgui),
    LibraryProduct("libcimgui_helper", :libcimgui_helper),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
