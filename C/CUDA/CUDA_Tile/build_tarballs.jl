# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CUDA_Tile"
version = v"13.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/NVIDIA/cuda-tile",
              "802d9378800a3b7c9f88875206e84b2746d6991b"),
    GitSource("https://github.com/llvm/llvm-project.git",
              "cfbb4cc31215d615f605466aef0bcfb42aa9faa5")
]

# Bash recipe for building across all platforms
script = raw"""
# Phase 1: bootstrap LLVM+MLIR
#
# Cross compilation of LLVM and CUDA Tile need native tools, so perform a bootstrap first.

cd $WORKSPACE/srcdir/llvm-project

mkdir native_build
cd native_build

CMAKE_FLAGS=()

# Install things into a temporary prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=$WORKSPACE/srcdir/llvm-project/native_install)

# Explicitly use our cmake toolchain file and tell CMake we're compiling natively
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=OFF)

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Match CUDA Tile build options
# (see https://github.com/NVIDIA/cuda-tile/blob/main/cmake/IncludeLLVM.cmake)
## Set LLVM options
CMAKE_FLAGS+=(-DLLVM_HOST_TRIPLE=${MACHTYPE})
CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD=host)
CMAKE_FLAGS+=(-DLLVM_INCLUDE_EXAMPLES=OFF)
CMAKE_FLAGS+=(-DLLVM_INCLUDE_TESTS=OFF)
CMAKE_FLAGS+=(-DLLVM_INCLUDE_BENCHMARKS=OFF)
CMAKE_FLAGS+=(-DLLVM_BUILD_EXAMPLES=OFF)
CMAKE_FLAGS+=(-DLLVM_ENABLE_ASSERTIONS=OFF)
CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS="mlir")
## Set MLIR options
CMAKE_FLAGS+=(-DMLIR_BUILD_EXAMPLES=OFF)
CMAKE_FLAGS+=(-DMLIR_ENABLE_BINDINGS_PYTHON=OFF)

# Disable dependencies the native tools don't need
CMAKE_FLAGS+=(-DLLVM_ENABLE_ZLIB=OFF)
CMAKE_FLAGS+=(-DLLVM_ENABLE_ZSTD=OFF)
CMAKE_FLAGS+=(-DLLVM_ENABLE_LIBXML2=OFF)

cmake ../llvm ${CMAKE_FLAGS[@]}

make -j${nproc} install


# Phase 2: cross-compile LLVM+MLIR

cd $WORKSPACE/srcdir/llvm-project

mkdir build
cd build

CMAKE_FLAGS=()
CMAKE_C_FLAGS=()
CMAKE_CXX_FLAGS=()

# Point to native tools directory
CMAKE_FLAGS+=(-DLLVM_NATIVE_TOOL_DIR=${WORKSPACE}/srcdir/llvm-project/native_build/bin)

# Also set individual tool paths explicitly
CMAKE_FLAGS+=(-DLLVM_TABLEGEN=${WORKSPACE}/srcdir/llvm-project/native_build/bin/llvm-tblgen)
CMAKE_FLAGS+=(-DLLVM_CONFIG_PATH=${WORKSPACE}/srcdir/llvm-project/native_build/bin/llvm-config)
CMAKE_FLAGS+=(-DLLVM_HEADERS_TABLEGEN=${WORKSPACE}/srcdir/llvm-project/native_build/bin/llvm-min-tblgen)
CMAKE_FLAGS+=(-DMLIR_TABLEGEN=${WORKSPACE}/srcdir/llvm-project/native_build/bin/mlir-tblgen)
CMAKE_FLAGS+=(-DMLIR_LINALG_ODS_YAML_GEN=${WORKSPACE}/srcdir/llvm-project/native_build/bin/mlir-linalg-ods-yaml-gen)
CMAKE_FLAGS+=(-DMLIR_PDLL_TABLEGEN=${WORKSPACE}/srcdir/llvm-project/native_build/bin/mlir-pdll)

# Install things into a temporary prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=$WORKSPACE/srcdir/llvm-project/install)

# Explicitly use our cmake toolchain file and tell CMake we're cross-compiling
if [[ "${target}" == *mingw* ]]; then
    # using Clang works around several (string table and eport symbol) limits on Windows
    CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_clang.cmake)

    # using Clang necessitates forcing pthread
    CMAKE_C_FLAGS+=(-pthread)
    CMAKE_CXX_FLAGS+=(-pthread)
else
    CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
fi
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=ON)

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Also install utils, since CUDA Tile's install target depends on it
CMAKE_FLAGS+=(-DLLVM_INSTALL_UTILS=True)

# Match CUDA Tile build options
# (see https://github.com/NVIDIA/cuda-tile/blob/main/cmake/IncludeLLVM.cmake)
## Set LLVM options
CMAKE_FLAGS+=(-DLLVM_INCLUDE_EXAMPLES=OFF)
CMAKE_FLAGS+=(-DLLVM_INCLUDE_TESTS=OFF)
CMAKE_FLAGS+=(-DLLVM_INCLUDE_BENCHMARKS=OFF)
CMAKE_FLAGS+=(-DLLVM_BUILD_EXAMPLES=OFF)
CMAKE_FLAGS+=(-DLLVM_ENABLE_ASSERTIONS=OFF)
CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS="mlir")
CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD="")
## Set MLIR options
CMAKE_FLAGS+=(-DMLIR_BUILD_EXAMPLES=OFF)
CMAKE_FLAGS+=(-DMLIR_ENABLE_BINDINGS_PYTHON=OFF)

cmake ../llvm ${CMAKE_FLAGS[@]} "-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS[*]}" "-DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS[*]}"

# For some reason, LLVM doesn't build the necessary tablegen files...
make llvm-headers mlir-generic-headers vt_gen

make -j${nproc} install


# Phase 3: build CUDA Tile

cd $WORKSPACE/srcdir/cuda-tile

install_license LICENSE.txt

# Patches
## Force linking against -pthread, which our llvm-config doesn't report
sed -i '/target_link_libraries(cuda-tile-tblgen/,/)/ s/)/  pthread\n)/' tools/cuda-tile-tblgen/CMakeLists.txt
## Fix missing include
sed -i 's|#include <vector>|#include <vector>\n#include <unordered_map>|' \
  tools/cuda-tile-tblgen/CudaTileOp.h

mkdir build
cd build/

CMAKE_FLAGS=()

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# Explicitly use our cmake toolchain file and tell CMake we're cross-compiling
if [[ "${target}" == *mingw* ]]; then
    # using Clang as we link against a Clang-built LLVM
    CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_clang.cmake)
    CMAKE_C_FLAGS+=(-pthread)
    CMAKE_CXX_FLAGS+=(-pthread)
else
    CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
fi
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=ON)

# Point CUDA Tile to our host compilers
CMAKE_FLAGS+=(-DNATIVE_C_COMPILER=$HOSTCC)
CMAKE_FLAGS+=(-DNATIVE_CXX_COMPILER=$HOSTCXX)

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Point to our MLIR installation
CMAKE_FLAGS+=(-DCUDA_TILE_USE_LLVM_INSTALL_DIR=${WORKSPACE}/srcdir/llvm-project/install)
CMAKE_FLAGS+=(-DCUDA_TILE_USE_NATIVE_LLVM_INSTALL_DIR=${WORKSPACE}/srcdir/llvm-project/native_install)

cmake .. ${CMAKE_FLAGS[@]} "-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS[*]}" "-DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS[*]}"
make -j${nproc} install

# XXX: remove third-party tools that aren't needed at run time
rm -rf ${prefix}/third_party
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [ # CUDA platforms
              Platform("x86_64", "linux"),
              Platform("aarch64", "linux"),
              Platform("x86_64", "windows"),
              # Development platforms
              Platform("aarch64", "macos"),
             ]

# The products that we will ensure are always built
products = [
    ExecutableProduct("cuda-tile-tblgen", :cuda_tile_tblgen),
    ExecutableProduct("cuda-tile-opt", :cuda_tile_opt),
    ExecutableProduct("cuda-tile-translate", :cuda_tile_translate)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
# Compiler versions taken from here:
# https://github.com/JuliaPackaging/Yggdrasil/blob/master/L/LLVM/LLVM_full%409.0.1/build_tarballs.jl
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6",
    preferred_gcc_version=v"13", # actually v10, but on Windows we use `.drectve -exclude-symbols`
    preferred_llvm_version=v"16")
