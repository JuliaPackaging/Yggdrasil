# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "tree_sitter_mlir"
version = v"0.0.1"

llvm_version = v"21.1.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource(
        "https://github.com/llvm/llvm-project/releases/download/llvmorg-$(llvm_version)/mlir-$(llvm_version).src.tar.xz",
        "75086853150ffe559a747559644c5c4b619b93f6fefc2bb2bfc3b143c97ae1ea"
    ),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
mv mlir-* mlir
mv mlir/utils/tree-sitter-mlir tree-sitter

# Install nodejs and npm
apk add --update nodejs npm

# Generate tree-sitter files
cd tree-sitter
npm ci
npm run compile
cd -

# Build parser library
BUILD_FLAGS=(-DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
mkdir build && cd build
cmake .. "${BUILD_FLAGS[@]}"
make -j${nproc}
make install LANGUAGE_NAME=libtreesitter_mlir

install_license $WORKSPACE/srcdir/mlir/LICENSE.TXT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = Platform[Platform("x86_64", "linux"; libc="gnu")]

# The products that we will ensure are always built
products = [
    LibraryProduct("libtreesitter_mlir", :libtreesitter_mlir)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")
