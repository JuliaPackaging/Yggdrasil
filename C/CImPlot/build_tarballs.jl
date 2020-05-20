# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CImPlot"
version = v"1.76.0"

# Collection of sources required to build CImGui
sources = [
    GitSource("https://github.com/ocornut/imgui.git",
              "5503c0a12e0c929e84b3f61b2cb4bb9177ea3da1"),

    GitSource("https://github.com/cimgui/cimplot.git",
              "8799c69b20081a744f44bb1ff9d39f6c8d8f23a1"),

    GitSource("https://github.com/epezent/implot.git",
              "1353014bce7d330e612529cb6193d811281eabac"),

    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mv cmake/CMakeLists.txt ./
mv implot cimplot/
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
mkdir -p ${prefix}/share/licenses/${SRC_NAME}
mv ../cimplot/LICENSE ${prefix}/share/licenses/${SRC_NAME}/LICENSE_cimplot
mv ../cimplot/implot/LICENSE ${prefix}/share/licenses/${SRC_NAME}/LICENSE_implot
mv ../imgui/LICENSE ${prefix}/share/licenses/${SRC_NAME}/LICENSE_imgui
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcimplot", :libcimplot),
    FileProduct("share/compile_commands.json", :compile_commands)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
