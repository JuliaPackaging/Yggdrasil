# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "gmsh"
version = v"4.7.1"

# Collection of sources required to build Gmsh
sources = [
    GitSource("https://gitlab.onelab.info/gmsh/gmsh.git", "8417af5701df5fb2d4e208424f1477be21f65c3c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/gmsh
install_license LICENSE.txt
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DENABLE_BUILD_DYNAMIC=1 ..
make
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libgmsh", "gmsh"], :libgmsh),
#   ExecutableProduct(prefix, "gmsh", :gmsh)
]

# Dependencies that must be installed before this package can be built
dependencies = [
   #"https://github.com/JuliaLinearAlgebra/OpenBLASBuilder/releases/download/v0.3.0-3/build_OpenBLAS.v0.3.0.jl" 
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,  preferred_gcc_version=v"5.3")

