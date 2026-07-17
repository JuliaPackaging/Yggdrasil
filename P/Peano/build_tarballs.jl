# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Peano"
version = v"21.0.0" # You can adjust this to match the LLVM fork version (e.g., 23.0.0-dev)

# Peano is the AMD/Xilinx fork of LLVM for compiling C/C++ to AIEngine processors.
sources = [
    GitSource(
        "https://github.com/Xilinx/llvm-aie.git",
        "fca3c2f87734485a529bf2eb4b1678a54ea08970", # Replace with the specific commit mlir-aie expects
    ),
]

script = raw"""
cd ${WORKSPACE}/srcdir/llvm-aie

CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# We need clang to compile C/C++ into AIE IR, and lld to link the AIE ELF binaries
CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS="clang;lld")

# Build for host architectures (to allow standard operations) and the AIE target.
# In the Peano fork, AIE is usually surfaced as an experimental target.
CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD="X86;AArch64")
CMAKE_FLAGS+=(-DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD="AIE")

# Strip out unnecessary LLVM components to drastically reduce build time
CMAKE_FLAGS+=(-DLLVM_BUILD_EXAMPLES=OFF)
CMAKE_FLAGS+=(-DLLVM_INCLUDE_EXAMPLES=OFF)
CMAKE_FLAGS+=(-DLLVM_INCLUDE_TESTS=OFF)
CMAKE_FLAGS+=(-DLLVM_INCLUDE_BENCHMARKS=OFF)
CMAKE_FLAGS+=(-DLLVM_ENABLE_BINDINGS=OFF)
CMAKE_FLAGS+=(-DLLVM_ENABLE_OCAMLDOC=OFF)
CMAKE_FLAGS+=(-DLLVM_ENABLE_ZSTD=OFF)
CMAKE_FLAGS+=(-DLLVM_ENABLE_LIBXML2=OFF)
CMAKE_FLAGS+=(-DLLVM_ENABLE_ZLIB=FORCE_ON)

# The LLVM build system expects to be run from the 'llvm' subdirectory
cmake -B build -S llvm -GNinja ${CMAKE_FLAGS[@]}
ninja -C build -j${nproc} install

install_license llvm/LICENSE.TXT
"""

# Peano runs on the host (e.g., a Ryzen AI laptop or Linux workstation) 
# to cross-compile code for the NPU.
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("x86_64", "windows"),
]
platforms = expand_cxxstring_abis(platforms)

# Extract the compiler drivers, linker, and IR optimizers
products = [
    ExecutableProduct("clang", :clang),
    ExecutableProduct("clang++", :clangxx),
    ExecutableProduct("lld", :lld),
    ExecutableProduct("llc", :llc),
    ExecutableProduct("opt", :opt),
]

# Zlib is required by LLVM
dependencies = Dependency[
    Dependency("Zlib_jll"),
]

# LLVM needs C++17 and a modern compiler
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"10", julia_compat = "1.10"
)
