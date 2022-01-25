# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "rocBLAS"
version = v"4.2.0"

# Collection of sources required to build
sources = [
    ArchiveSource("https://github.com/ROCmSoftwarePlatform/rocBLAS/archive/rocm-$(version).tar.gz",
                  "547f6d5d38a41786839f01c5bfa46ffe9937b389193a8891f251e276a1a47fb0"),
    GitSource("https://github.com/ROCmSoftwarePlatform/Tensile.git",
              "3438af228dc812768b20a068b0285122f327fa5b"), # 4.2.0
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/rocBLAS*/

TENSILE_DIR=$WORKSPACE/srcdir/Tensile
TENSILE_ARCHITECTURES="all,gfx803,gfx900,gfx906,gfx908"
# -DAMDGPU_TARGETS=$(echo $amdgpu_targets | tr ',' ';') \

# TODO: $HIPCXXFLAGS .= " -D__HIP__ -D__HIP_PLATFORM_HCC__";

apk add py3-yaml msgpack-c-dev py3-msgpack boost-dev python3-dev yaml-dev py3-wheel

# Add explicit device norm calls
atomic_patch -p1 $WORKSPACE/srcdir/patches/add-norm.patch

mkdir build && cd build

# clang doesn't support --genco
sed -e "s:hipFlags = \[\"--genco\", :hipFlags = \[:" -i $TENSILE_DIR/Tensile/TensileCreateLibrary.py

# YAML write errors
sed -e "s/Impl::inputOne(io, key, \*value)/Impl::inputOne(io, key.str(), \*value)/g" -i $TENSILE_DIR/Tensile/Source/lib/include/Tensile/llvm/YAML.hpp

ln -s ${prefix}/bin/clang ${prefix}/tools/clang
export ROCM_PATH=${prefix}
export HIP_CLANG_PATH=$WORKSPACE/destdir/tools
export HIP_CLANG_HCC_COMPAT_MODE=1
export HIP_RUNTIME=rocclr
export HIP_COMPILER=clang
export HIP_PLATFORM=amd
#export HIPCC_VERBOSE=7 # this breaks Tensile's parsing of `hipcc --version`
export PATH=${prefix}/tools:${prefix}/hip/bin:$PATH
#-DTensile_LIBRARY_FORMAT=msgpack \
cmake -DCMAKE_PREFIX_PATH=${prefix} \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CXX_COMPILER=$WORKSPACE/destdir/hip/bin/hipcc \
      -DBUILD_CLIENTS_TESTS=OFF \
      -DBUILD_CLIENTS_BENCHMARKS=OFF \
      -DBUILD_CLIENTS_SAMPLES=OFF \
      -DRUN_HEADER_TESTING=OFF \
      -DBUILD_WITH_TENSILE=ON \
      -DTensile_ARCHITECTURE=gfx900 \
      -DTensile_TEST_LOCAL_PATH=$TENSILE_DIR \
      -DTensile_COMPILER=hipcc \
      -DTensile_LOGIC=asm_full \
      -DTensile_CODE_OBJECT_VERSION=V3 \
      -DBUILD_WITH_TENSILE_HOST=OFF \
      ..
make -j${nproc}
make install
cd .. && install_license LICENSE.md
rm ${prefix}/tools/clang
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    # TODO: cxx03
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct(["librocblas", "librocblas.so.0"], :librocblas, ["rocblas/lib"]),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version=v"4.2.0")),
    Dependency("hsa_rocr_jll"; compat="4.2.0"),
    Dependency("ROCmCompilerSupport_jll"; compat="4.2.0"),
    Dependency("ROCmOpenCLRuntime_jll"; compat="4.2.0"),
    Dependency("HIP_jll"; compat="4.2.0"),
    Dependency("rocm_cmake_jll"),
    Dependency("rocminfo_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               julia_compat="1.7",
               preferred_gcc_version=v"8", preferred_llvm_version=v"11")
