# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "AMDGPU_ROCm_Clang"
version = v"23.0.0"

# A native clang (plus TableGen tools) from ROCm's llvm-project fork, built
# from the same commit as AMDGPU_LLVM_Backend.  This is meant to be used as a
# HostBuildDependency, both for compiling the ROCm device libraries to AMDGPU
# bitcode and for providing the native tblgen tools when cross-compiling
# AMDGPU_LLVM_Backend itself.
sources = [
    GitSource("https://github.com/ROCm/llvm-project",
              "46fcb339fb61119b337f973c7ca9e710a319fdd0")
]

script = raw"""
cd llvm-project/llvm
LLVM_SRCDIR=$(pwd)

install_license LICENSE.TXT

# First build the native tblgen tools, since LLVM's cross-compile setup is
# kind of borked, we just build them natively ourselves, directly.  :/
mkdir ${WORKSPACE}/bootstrap
pushd ${WORKSPACE}/bootstrap
CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD:STRING=AMDGPU)
CMAKE_FLAGS+=(-DLLVM_HOST_TRIPLE=${MACHTYPE})
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS='clang')
CMAKE_FLAGS+=(-DLLVM_INCLUDE_TESTS=OFF)
CMAKE_FLAGS+=(-DLLVM_INCLUDE_EXAMPLES=OFF)
CMAKE_FLAGS+=(-DLLVM_INCLUDE_BENCHMARKS=OFF)
CMAKE_FLAGS+=(-DLLVM_INCLUDE_DOCS=OFF)
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=False)
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN})
cmake -GNinja ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]}
ninja -j${nproc} llvm-tblgen clang-tblgen llvm-config
popd

# The actual build
mkdir ${WORKSPACE}/build && cd ${WORKSPACE}/build
CMAKE_FLAGS=()

# Tell LLVM where our pre-built tblgen tools are
CMAKE_FLAGS+=(-DLLVM_TABLEGEN=${WORKSPACE}/bootstrap/bin/llvm-tblgen)
CMAKE_FLAGS+=(-DCLANG_TABLEGEN=${WORKSPACE}/bootstrap/bin/clang-tblgen)
CMAKE_FLAGS+=(-DLLVM_CONFIG_PATH=${WORKSPACE}/bootstrap/bin/llvm-config)

# We only need clang to emit AMDGPU bitcode
CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD=AMDGPU)
CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS='clang')

# Slim down the clang build
CMAKE_FLAGS+=(-DCLANG_ENABLE_STATIC_ANALYZER=OFF)
CMAKE_FLAGS+=(-DLLVM_INCLUDE_TESTS=OFF)
CMAKE_FLAGS+=(-DLLVM_INCLUDE_EXAMPLES=OFF)
CMAKE_FLAGS+=(-DLLVM_INCLUDE_BENCHMARKS=OFF)
CMAKE_FLAGS+=(-DLLVM_INCLUDE_DOCS=OFF)

# Also install llvm-tblgen, so AMDGPU_LLVM_Backend doesn't need a native
# bootstrap build of its own
CMAKE_FLAGS+=(-DLLVM_INSTALL_UTILS=ON)

# Avoid unnecessary dependencies
CMAKE_FLAGS+=(-DLLVM_ENABLE_ZLIB=OFF)
CMAKE_FLAGS+=(-DLLVM_ENABLE_ZSTD=OFF)
CMAKE_FLAGS+=(-DLLVM_ENABLE_LIBXML2=OFF)

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

cmake -GNinja ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]}

# Install everything (including static libraries and the CMake exports), so
# that the device libraries can be built against this via find_package(LLVM)
ninja -j${nproc} install
"""

# This is a host tool: musl for use as a HostBuildDependency in BinaryBuilder,
# glibc for local use.
platforms = [
    Platform("x86_64", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="glibc"),
]
platforms = expand_cxxstring_abis(platforms)

products = Product[
    ExecutableProduct("clang", :clang),
    ExecutableProduct("llvm-link", :llvm_link),
    ExecutableProduct("opt", :opt),
    ExecutableProduct("llvm-tblgen", :llvm_tblgen),
    ExecutableProduct("llvm-config", :llvm_config),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script,
               platforms, products, dependencies;
               preferred_gcc_version=v"10", julia_compat="1.6")
