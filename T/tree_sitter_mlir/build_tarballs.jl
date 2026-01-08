# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "tree_sitter_mlir"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/artagnon/tree-sitter-mlir.git",
        "c7eec06be8a9ddae688e1b03fca2eed79e9801c4"
    ),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
mv tree-sitter-mlir tree-sitter

# Build parser library
BUILD_FLAGS=(-DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
mkdir build && cd build
cmake .. "${BUILD_FLAGS[@]}"
make -j${nproc}
make install LANGUAGE_NAME=libtreesitter_mlir

install_license $WORKSPACE/srcdir/tree-sitter/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libtreesitter_mlir", :libtreesitter_mlir)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")
