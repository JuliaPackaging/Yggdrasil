# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "mlir_aie"
version = v"1.3.5"

# mlir-aie pins a commit of the ROCm llvm-project fork rather than tracking a
# release (utils/clone-llvm.sh), and that LLVM calls itself 23.0.0-dev, so no
# LLVM_full_jll matches it. MLIR's C++ API is not stable between releases, and
# mlir-aie uses plenty of it, so the pinned commit is built here rather than
# substituting whichever LLVM Yggdrasil happens to carry. This follows
# C/CUDA/CUDA_Tile, which has the same problem.
sources = [
    GitSource(
        "https://github.com/Xilinx/mlir-aie.git",
        "54777cfabfe42908b10da7cc1b31224f8865cb31",
    ),
    GitSource(
        "https://github.com/ROCm/llvm-project.git",
        "46fcb339fb61119b337f973c7ca9e710a319fdd0",   # see utils/clone-llvm.sh
    ),
]

script = raw"""
# Remove the old system CMake so that the modern HostBuildDependency version takes precedence
apk del cmake

# Phase 1: LLVM + MLIR, as mlir-aie configures it (utils/build-llvm.sh)
#
# Only x86_64-linux-gnu is built, and the builder is x86_64-linux-gnu, so the
# tablegen binaries this produces run here and no native bootstrap is needed. Adding
# a platform means adding a bootstrap phase first, the way C/CUDA/CUDA_Tile does:
# tablegen has to execute during the mlir-aie build.
cd ${WORKSPACE}/srcdir/llvm-project

CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${WORKSPACE}/srcdir/llvm-install)
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS=mlir)
CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD=host)
CMAKE_FLAGS+=(-DLLVM_BUILD_EXAMPLES=OFF)
CMAKE_FLAGS+=(-DLLVM_INCLUDE_EXAMPLES=OFF)
CMAKE_FLAGS+=(-DLLVM_INCLUDE_TESTS=OFF)
CMAKE_FLAGS+=(-DLLVM_INCLUDE_BENCHMARKS=OFF)
CMAKE_FLAGS+=(-DLLVM_ENABLE_OCAMLDOC=OFF)
CMAKE_FLAGS+=(-DLLVM_ENABLE_BINDINGS=OFF)
CMAKE_FLAGS+=(-DLLVM_OPTIMIZED_TABLEGEN=OFF)
# mlir-aie is built with RTTI, so MLIR has to be too or the link fails.
CMAKE_FLAGS+=(-DLLVM_ENABLE_RTTI=ON)
CMAKE_FLAGS+=(-DLLVM_INSTALL_UTILS=ON)
CMAKE_FLAGS+=(-DLLVM_ENABLE_ASSERTIONS=OFF)
CMAKE_FLAGS+=(-DMLIR_ENABLE_BINDINGS_PYTHON=OFF)
CMAKE_FLAGS+=(-DLLVM_ENABLE_ZSTD=OFF)
CMAKE_FLAGS+=(-DLLVM_ENABLE_LIBXML2=OFF)

cmake -B build -S llvm -GNinja ${CMAKE_FLAGS[@]}
ninja -C build -j${nproc} install


# Phase 2: mlir-aie
cd ${WORKSPACE}/srcdir/mlir-aie

# Fetch third-party submodules (like bootgen) that GitSource ignores by default
git submodule update --init --recursive

# Fix permissions on Python generation scripts so the build system can execute them
chmod +x utils/*.py
chmod +x utils/*.sh

install_license LICENSE

CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

CMAKE_FLAGS+=(-DLLVM_DIR=${WORKSPACE}/srcdir/llvm-install/lib/cmake/llvm)
CMAKE_FLAGS+=(-DMLIR_DIR=${WORKSPACE}/srcdir/llvm-install/lib/cmake/mlir)
CMAKE_FLAGS+=(-DCMAKE_MODULE_PATH=${WORKSPACE}/srcdir/mlir-aie/cmake/modulesXilinx)

CMAKE_FLAGS+=(-DLLVM_ENABLE_RTTI=ON)
CMAKE_FLAGS+=(-DLLVM_ENABLE_ASSERTIONS=OFF)

# The Python bindings want an interpreter and pybind at build time; the tools below
# are this JLL's interface instead.
CMAKE_FLAGS+=(-DAIE_ENABLE_BINDINGS_PYTHON=OFF)
CMAKE_FLAGS+=(-DAIE_ENABLE_PYTHON_PASSES=OFF)
CMAKE_FLAGS+=(-DAIE_ENABLE_XRT_PYTHON_BINDINGS=OFF)

# chess-clang needs the proprietary Vitis toolchain; the visualizer and LSP server
# are editor conveniences rather than part of the compile path.
CMAKE_FLAGS+=(-DAIE_BUILD_CHESS_CLANG=OFF)
CMAKE_FLAGS+=(-DAIE_BUILD_VISUALIZE=OFF)
CMAKE_FLAGS+=(-DAIE_BUILD_LSP_SERVER=OFF)

# The AIE runtime libraries are compiled *for the accelerator* by Peano, a separate
# LLVM fork that is not here; this builds the host tools only.
CMAKE_FLAGS+=(-DAIE_RUNTIME_TARGETS=)
CMAKE_FLAGS+=(-DAIE_RUNTIME_TEST_TARGET=)

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
# aiecc is the compile driver: it orchestrates the full lowering and links
# bootgen-lib (built from third_party/bootgen, needs OpenSSL) for direct PDI
# generation, so a design can be taken to a PDI without the Python stack. CDO
# and the NPU instruction stream are emitted by aie-translate, which already
# links xaienginecdo_static from the same submodule. `add_subdirectory(bootgen)`
# and `add_subdirectory(aiecc)` are unconditional, so no extra flags are needed.
ninja -C build -j${nproc} aie-opt aie-translate aiecc

install -Dm755 build/bin/aie-opt "${bindir}/aie-opt${exeext}"
install -Dm755 build/bin/aie-translate "${bindir}/aie-translate${exeext}"
install -Dm755 build/bin/aiecc "${bindir}/aiecc${exeext}"
"""

# mlir-aie's tools drive AIE devices from a Linux host, and the NPUs they target are
# x86_64. Building elsewhere would produce tools with nothing to talk to -- and see
# the note about tablegen in phase 1 before adding a platform.
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
]
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("aie-opt", :aie_opt),
    ExecutableProduct("aie-translate", :aie_translate),
    ExecutableProduct("aiecc", :aiecc),
]

# LLVM and MLIR are built above rather than depended on, so there is nothing here
# but what the tools link against besides.
dependencies = [
    Dependency("Zlib_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("OpenSSL_jll"), # Required by the bootgen tool
    HostBuildDependency("CMake_jll"), # Pulls in the newest stable version of CMake for the host system
]

# MLIR needs C++17, and this much of it needs a compiler that will not fold under it.
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"10", julia_compat = "1.10"
)
