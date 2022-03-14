# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "glm"
version = v"0.9.9"

# Collection of sources required to build this package
sources = [
    GitSource("https://github.com/g-truc/glm.git",
              "6ad79aae3eb5bf809c30bf1168171e9e55857e45"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/glm*
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
    FileProduct("include/glm/glm.hpp", :glm_hpp),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
