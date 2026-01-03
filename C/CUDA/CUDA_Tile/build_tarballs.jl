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

mkdir build
cd build

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

cmake -GNinja ../llvm ${CMAKE_FLAGS[@]}

ninja -j${nproc} install

cd ..
rm -rf build


# Phase 2: cross-compile LLVM+MLIR

cd $WORKSPACE/srcdir/llvm-project

mkdir build
cd build

CMAKE_FLAGS=()

# Tell LLVM where our pre-built tblgen tools are
CMAKE_FLAGS+=(-DLLVM_TABLEGEN=${WORKSPACE}/srcdir/llvm-project/native_install/bin/llvm-tblgen)
CMAKE_FLAGS+=(-DLLVM_CONFIG_PATH=${WORKSPACE}/srcdir/llvm-project/native_install/bin/llvm-config)

# Install things into a temporary prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=$WORKSPACE/srcdir/llvm-project/install)

# Explicitly use our cmake toolchain file and tell CMake we're cross-compiling
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=ON)

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

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

cmake -GNinja ../llvm ${CMAKE_FLAGS[@]}
ninja -j${nproc} install

cd ..
rm -rf build


# Phase 3: build CUDA Tile

cd $WORKSPACE/srcdir/cuda-tile

install_license LICENSE.txt

# Force linking against -pthread, which our llvm-config doesn't report
sed -i '/target_link_libraries(cuda-tile-tblgen/,/)/ s/)/  pthread\n)/' tools/cuda-tile-tblgen/CMakeLists.txt

mkdir build
cd build/

CMAKE_FLAGS=()

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# Explicitly use our cmake toolchain file and tell CMake we're cross-compiling
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=ON)

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Point to our MLIR installation
CMAKE_FLAGS+=(-DCUDA_TILE_USE_LLVM_INSTALL_DIR=${WORKSPACE}/srcdir/llvm-project/install)
CMAKE_FLAGS+=(-DCUDA_TILE_USE_NATIVE_LLVM_INSTALL_DIR=${WORKSPACE}/srcdir/llvm-project/native_install)

cmake -GNinja .. ${CMAKE_FLAGS[@]}
ninja -j${nproc}

# XXX: `ninja install` doesn't work
mkdir -p ${bindir}
mv bin/cuda-tile-tblgen ${bindir}
mv bin/cuda-tile-opt ${bindir}
mv bin/cuda-tile-translate ${bindir}
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
    preferred_gcc_version=v"10",
    preferred_llvm_version=v"16")
