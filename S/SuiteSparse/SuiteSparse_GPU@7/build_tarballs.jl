include("../common.jl")

using Base.BinaryPlatforms: arch, os

name = "SuiteSparse_GPU"
version_str = "7.5.1"
version = VersionNumber(version_str)

sources = suitesparse_sources(version)

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SuiteSparse

# Needs cmake >= 3.22 provided by jll
apk del cmake

# Ensure CUDA is on the path
export CUDA_HOME=${WORKSPACE}/destdir/cuda;
export PATH=$PATH:$CUDA_HOME/bin
export CUDACXX=$CUDA_HOME/bin/nvcc

# nvcc thinks the libraries are located inside lib64, but the SDK actually has them in lib
ln -s ${CUDA_HOME}/lib ${CUDA_HOME}/lib64

# Disable OpenMP as it will probably interfere with blas threads and Julia threads
FLAGS+=(INSTALL="${prefix}" INSTALL_LIB="${libdir}" INSTALL_INCLUDE="${prefix}/include" CFOPENMP=)

BLAS_NAME=blastrampoline
if [[ "${target}" == *-mingw* ]]; then
    BLAS_LIB=${BLAS_NAME}-5
else
    BLAS_LIB=${BLAS_NAME}
fi

# Enable CUDA
FLAGS+=(CUDA_PATH="$prefix/cuda")

if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi

if [[ ${nbits} == 64 ]]; then
    CMAKE_OPTIONS=(
        -DBLAS64_SUFFIX="_64"
        -DSUITESPARSE_USE_64BIT_BLAS=YES
    )
else
    CMAKE_OPTIONS=(
        -DSUITESPARSE_USE_64BIT_BLAS=NO
    )
fi

PROJECTS_TO_BUILD="cholmod;spqr"

cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_RELEASE_POSTFIX="_cuda" \
      -DBUILD_STATIC_LIBS=OFF \
      -DBUILD_TESTING=OFF \
      -DSUITESPARSE_ENABLE_PROJECTS=${PROJECTS_TO_BUILD} \
      -DSUITESPARSE_DEMOS=OFF \
      -DSUITESPARSE_USE_STRICT=ON \
      -DSUITESPARSE_USE_CUDA=ON \
      -DSUITESPARSE_USE_FORTRAN=OFF \
      -DSUITESPARSE_USE_OPENMP=OFF \
      -DSUITESPARSE_USE_SYSTEM_SUITESPARSE_CONFIG=ON \
      -DSUITESPARSE_USE_SYSTEM_AMD=ON \
      -DSUITESPARSE_USE_SYSTEM_COLAMD=ON \
      -DSUITESPARSE_USE_SYSTEM_CAMD=ON \
      -DSUITESPARSE_USE_SYSTEM_CCOLAMD=ON \
      -DCHOLMOD_PARTITION=ON \
      -DBLAS_FOUND=1 \
      -DBLAS_LIBRARIES="${libdir}/lib${BLAS_LIB}.${dlext}" \
      -DBLAS_LINKER_FLAGS="${BLAS_LIB}" \
      -DBLA_VENDOR="${BLAS_NAME}" \
      -DLAPACK_LIBRARIES="${libdir}/lib${BLAS_LIB}.${dlext}" \
      -DLAPACK_LINKER_FLAGS="${BLAS_LIB}" \
      "${CMAKE_OPTIONS[@]}" \
      .

make -j${nproc}
make install

install_license LICENSE.txt
"""

# Override the default platforms
platforms = CUDA.supported_platforms()
filter!(p -> arch(p) == "x86_64", platforms)

# Add dependency on SuiteSparse_jll
push!(dependencies, Dependency("SuiteSparse_jll"; compat = "=$version_str" ))

# build SuiteSparse_GPU for all supported CUDA toolkits
for platform in platforms
    should_build_platform(triplet(platform)) || continue

    # Need the static SDK to let CMake detect the compiler properly
    cuda_deps = CUDA.required_dependencies(platform, static_sdk=true)

    build_tarballs(ARGS, name, version, sources, script, [platform],
                   gpu_products, [dependencies; cuda_deps]; lazy_artifacts=true,
                   julia_compat="1.11",preferred_gcc_version=v"9",
                   augment_platform_block=CUDA.augment,
                   skip_audit=true, dont_dlopen=true)
end
