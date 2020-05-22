# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
using Pkg
name = "CImPlot"
version = v"0.0.1"

# Collection of sources required to build CImGui
sources = [
    GitSource("https://github.com/cimgui/cimplot.git",
              "8799c69b20081a744f44bb1ff9d39f6c8d8f23a1"),

    GitSource("https://github.com/epezent/implot.git",
              "1353014bce7d330e612529cb6193d811281eabac"),

    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mv cmake/CMakeLists.txt ./cimplot/
mv implot cimplot/
cd cimplot/
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
mkdir -p ${prefix}/share/licenses/${SRC_NAME}
mv ../LICENSE ${prefix}/share/licenses/${SRC_NAME}/LICENSE_cimplot
mv ../implot/LICENSE ${prefix}/share/licenses/${SRC_NAME}/LICENSE_implot
mv ../../imgui/LICENSE.txt ${prefix}/share/licenses/${SRC_NAME}/LICENSE_imgui
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
dependencies = [
                Dependency(PackageSpec(name="CImGui_jll", version=v"1.75.0")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
