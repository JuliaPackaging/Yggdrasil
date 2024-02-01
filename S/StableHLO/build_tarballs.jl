# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "StableHLO"
version = v"0.14.6"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/openxla/stablehlo.git", "8816d0581d9a5fb7d212affef858e991a349ad6b"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/stablehlo

[[ "$(uname)" != "Darwin" ]] && LLVM_ENABLE_LLD="ON" || LLVM_ENABLE_LLD="OFF"

# build MLIR
cd stablehlo

mkdir build && cd build
cmake .. -GNinja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_LLD="$LLVM_ENABLE_LLD" \
    -DLLVM_ENABLE_ASSERTIONS=OFF \
    -DMLIR_DIR=${PWD}/../llvm-build/lib/cmake/mlir \
    -DBUILD_SHARED_LIBS=ON
cmake --build . --target install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("stablehlo-opt", :stablehlo_opt),
    ExecutableProduct("stablehlo-translate", :stablehlo_translate),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("MLIR_jll", compat=v"17.0.6"),
    Dependency("LLVM_jll", compat=v"17.0.6"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.10", preferred_llvm_version=v"17")
