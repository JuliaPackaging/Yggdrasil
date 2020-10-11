# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CSFML"
version = v"2.5.0"

# Collection of sources required to build CImGui
sources = [
    GitSource("https://github.com/SFML/CSFML.git",
              "61f17e3c1d109b65ef7e3e3ea1d06961da130afc")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd CSFML
mkdir build && cd build
CMAKE_FLAGS="-DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release"
if [[ "${target}" == *mingw* ]]; then
CMAKE_FLAGS="${CMAKE_FLAGS} -DCSFML_LINK_SFML_STATICALLY=false"
fi
cmake .. ${CMAKE_FLAGS}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "macos"),
    Platform("i686", "windows"),
    Platform("x86_64", "windows")
]
platforms = expand_cxxstring_abis(platforms; skip=!Sys.iswindows)


# The products that we will ensure are always built
products = [
    LibraryProduct(["libcsfml-graphics", "csfml-graphics"], :libcsfml_graphics),
    LibraryProduct(["libcsfml-system", "csfml-system"], :libcsfml_system),
    LibraryProduct(["libcsfml-network", "csfml-network"], :libcsfml_network),
    LibraryProduct(["libcsfml-window", "csfml-window"], :libcsfml_window),
    LibraryProduct(["libcsfml-audio", "csfml-audio"], :libcsfml_audio)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("SFML_jll", v"2.5.1")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)