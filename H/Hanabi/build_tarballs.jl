# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Hanabi"
version = v"2021.01.23"

# Collection of sources required to build CImGui
sources = [
    GitSource("https://github.com/deepmind/hanabi-learning-environment.git",
              "4210e0edadb636fdccf528f75943df685085878b"),

    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/hanabi-learning-environment/hanabi_learning_environment/
rm ./CMakeLists.txt
mv ../../wrapper/CMakeLists.txt ./
mkdir -p build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
install_license ../../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libhanabi", :libhanabi),
    FileProduct("include/pyhanabi.h", :libhanabi_h),
    FileProduct("share/compile_commands.json", :compile_commands)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
