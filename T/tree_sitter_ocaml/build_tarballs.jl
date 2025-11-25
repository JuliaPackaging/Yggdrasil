# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "tree_sitter_ocaml"
version = v"0.24.2"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/tree-sitter/tree-sitter-ocaml.git",
        "0cc270ff90ca09c29d0f2f9dec69ddfef55a3eff"
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
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libtreesitter_ocaml", :libtreesitter_ocaml),
    LibraryProduct("libtreesitter_ocaml_interface", :libtreesitter_ocaml_interface),
    LibraryProduct("libtreesitter_ocaml_type", :libtreesitter_ocaml_type),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
