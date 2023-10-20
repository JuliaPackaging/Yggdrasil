# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CImGuiPack"
version = v"0.2.0"

# Collection of sources required to build CImGuiPack
sources = [
    GitSource("https://github.com/JuliaImGui/cimgui-pack.git",
              "af96d7d92c8b430af35e4b87c1260b234ccf9b5a")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cimgui-pack
git submodule update --init --recursive
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"5")
