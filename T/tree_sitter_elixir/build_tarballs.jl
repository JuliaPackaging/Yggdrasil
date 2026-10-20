# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "tree_sitter_elixir"
version = v"0.3.5"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/elixir-lang/tree-sitter-elixir.git",
        "e2d9e6e0e76b0c436fa48a0b8c32a031d0cbdf49"
    ),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mv tree-sitter-* tree-sitter

BUILD_FLAGS=(-DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
mkdir build && cd build
cmake .. "${BUILD_FLAGS[@]}"
make -j${nproc}
make install

cd ..
cp -r tree-sitter/queries $WORKSPACE/destdir/
install_license tree-sitter/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libtreesitter_elixir", :libtreesitter_elixir),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
