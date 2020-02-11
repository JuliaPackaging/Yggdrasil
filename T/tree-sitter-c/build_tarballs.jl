# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "tree-sitter-c"
version = v"0.16.0"

# Collection of sources required to complete build
sources = [
    FileSource("https://github.com/tree-sitter/tree-sitter.git", "d8c3f472d23ad79f519651d5cf715b56467d35d0")
    FileSource("https://github.com/tree-sitter/tree-sitter-c.git", "6002fcd5e86bb1e8670157bb008b97dbaf656d95")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
echo 'cmake_minimum_required(VERSION 3.13)
project(treesitter)
set(CMAKE_C_STANDARD 99)

include_directories(tree-sitter/lib/include tree-sitter/lib/src)

add_library(treesitter tree-sitter/lib/src/lib.c)

include_directories(tree-sitter-c/src)
add_library(treesitter_c SHARED tree-sitter-c/src/parser.c)
target_link_libraries(treesitter_c treesitter)

install(TARGETS treesitter_c DESTINATION lib CONFIGURATIONS Release)' > CMakeLists.txt
BUILD_FLAGS=(-DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
mkdir build && cd build
cmake .. "${BUILD_FLAGS[@]}"
make -j${nproc}
make install
mkdir ${prefix}/include
cp ../tree-sitter/lib/include/tree_sitter/api.h ${prefix}/include/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libtreesitter_c", :libtreesitter_c)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
