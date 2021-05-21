# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CImGuiPack"
version = v"0.1.0"

# Collection of sources required to build CImGuiPack
sources = [
    GitSource("https://github.com/Gnimuc/cimgui-pack.git",
              "4ac1694b8c9739b152c949f11ae6de9c54d1badf")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd cimgui-pack
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
install_license ../cimgui/LICENSE ../cimgui/imgui/LICENSE.txt ../cimplot/LICENSE ../cimplot/implot/LICENSE ../cimnodes/imnodes/LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcimgui", :libcimgui),
    FileProduct("share/compile_commands.json", :compile_commands)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
