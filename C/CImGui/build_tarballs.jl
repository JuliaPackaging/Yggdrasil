# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CImGui"
version = v"1.82.0"

# Collection of sources required to build CImGui
sources = [
    GitSource("https://github.com/ocornut/imgui.git",
              "64aab8480a5643cec1880af17931963a90a8f990"),

    GitSource("https://github.com/cimgui/cimgui.git",
              "83f729b09313749a56948604c4bc13492ac47e00"),

    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
rm cimgui/CMakeLists.txt
mv imgui wrapper/CMakeLists.txt cimgui/
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
    LibraryProduct("libimgui-cpp", :libimgui),
    LibraryProduct("libcimgui", :libcimgui),
    FileProduct("share/compile_commands.json", :compile_commands)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
