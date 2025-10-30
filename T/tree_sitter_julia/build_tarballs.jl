# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "tree_sitter_julia"
version = v"0.23.1"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/tree-sitter/tree-sitter-julia.git",
        "a8e1262997d5a45520a06cbe1b86c0737d507054"
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
if [ -d tree-sitter/queries ]; then
    cp -r tree-sitter/queries $WORKSPACE/destdir/
fi
if [ -f tree-sitter/LICENSE ]; then
    install_license tree-sitter/LICENSE
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libtreesitter_julia", :libtreesitter_julia),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
