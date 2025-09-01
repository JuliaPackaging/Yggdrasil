using BinaryBuilder
import Pkg: PackageSpec
using Base.BinaryPlatforms: arch, os, tags

# Heavily Copies from: https://github.com/JuliaPackaging/Yggdrasil/blob/master/S/SuiteSparse/SuiteSparse_GPU%407/build_tarballs.jl

const YGGDRASIL_DIR = "../../"
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "legate"
version = v"25.5" # Year.Month
sources = [
    GitSource("https://github.com/nv-legate/legate.git","8a619fa468a73f9766f59ac9a614c0ee084ecbdd"),
    DirectorySource("./bundled"),
    FileSource("https://repo.anaconda.com/miniconda/Miniconda3-py311_24.3.0-0-Linux-x86_64.sh", 
                "4da8dde69eca0d9bc31420349a204851bfa2a1c87aeb87fe0c05517797edaac4", "miniconda.sh")
]

MIN_CUDA_VERSION = v"12.2"
MAX_CUDA_VERSION = v"12.8.999" #12.9?


script = raw"""

# We will build with clang
export CC="clang"
export CXX="clang++"
export BUILD_CXX=$(which clang++)
export BUILD_CC=$(which clang)

# Necessary operations to cross compile CUDA from x86_64 to aarch64
if [[ "${target}" == aarch64-linux-* ]]; then

   # Add /usr/lib/csl-musl-x86_64 to LD_LIBRARY_PATH to be able to use host nvcc
   export LD_LIBRARY_PATH="/usr/lib/csl-musl-x86_64:/usr/lib/csl-glibc-x86_64:${LD_LIBRARY_PATH}"
   
   # Make sure we use host CUDA executable by copying from the x86_64 CUDA redist
   NVCC_DIR=(/workspace/srcdir/cuda_nvcc-*-archive)
   rm -rf ${prefix}/cuda/bin
   cp -r ${NVCC_DIR}/bin ${prefix}/cuda/bin
   
   rm -rf ${prefix}/cuda/nvvm/bin
   cp -r ${NVCC_DIR}/nvvm/bin ${prefix}/cuda/nvvm/bin

   export NVCC_PREPEND_FLAGS="-ccbin='${CXX}'"
fi

# Put new CMake first on path
export PATH=${host_bindir}:$PATH

# Install Python 3.11 (via miniconda)
cd ${WORKSPACE}/srcdir
bash miniconda.sh -b -p ${host_bindir}/miniconda

# Create venv and install configure script dependencies
${host_bindir}/miniconda/bin/python -m venv ./venv
source ./venv/bin/activate
pip install --upgrade pip
pip install rich typing_extensions packaging

python -c "import rich, typing_extensions, packaging; print('Python deps installed and working!')"

cd ${WORKSPACE}/srcdir/legate

### Set Up CUDA ENV Vars

export CPPFLAGS="${CPPFLAGS} -I${prefix}/include"
export CFLAGS="${CFLAGS} -I${prefix}/include"
export LDFLAGS="${LDFLAGS} -L${prefix}/lib -L${prefix}/lib64"

export CUDA_HOME=${prefix}/cuda;
export PATH=$PATH:$CUDA_HOME/bin
export CUDACXX=$CUDA_HOME/bin/nvcc
export CUDA_LIB=${CUDA_HOME}/lib

ln -s ${CUDA_HOME}/lib ${CUDA_HOME}/lib64

./configure \
    --prefix=${prefix} \
    --with-cudac=${CUDACXX} \
    --with-cuda-dir=${CUDA_HOME} \
    --with-nccl-dir=${prefix} \
    --with-mpiexec-executable=${bindir}/mpiexec \
    --with-mpi-dir=${prefix} \
    --with-zlib-dir=${prefix} \
    --with-hdf5-vfd-gds=0 \
    --with-hdf5-dir=${prefix} \
    --num-threads=${nproc} \
    --with-cxx=${CXX} \
    --with-cc=${CC} \
    --CXXFLAGS="${CPPFLAGS}" \
    --CFLAGS="${CFLAGS}" \
    --with-clean \
    --cmake-executable=${host_bindir}/cmake \
    -- "-DCMAKE_TOOLCHAIN_FILE=/opt/toolchains/${bb_full_target}/target_${target}_clang.cmake" \
        "-DCMAKE_CUDA_HOST_COMPILER=$(which clang++)" \


# Patch redop header that is installed by configure script
cd ${WORKSPACE}/srcdir
atomic_patch -p1 ./legion_redop.patch

# Go back to main dir
cd ${WORKSPACE}/srcdir/legate

make install -j ${nproc} PREFIX=${prefix}
install_license ${WORKSPACE}/srcdir/legate/LICENSE

if [[ "${target}" == aarch64-linux-* ]]; then
   # ensure products directory is clean
   rm -rf ${prefix}/cuda
fi
"""

augment_platform_block = 
"""
using Base.BinaryPlatforms
module __CUDA
    $(CUDA.augment)
end

$(MPI.augment)

function augment_platform!(platform::Platform)
    augment_mpi!(platform)
    __CUDA.augment_platform!(platform)
end
"""

platforms = CUDA.supported_platforms(; min_version = MIN_CUDA_VERSION, max_version = MAX_CUDA_VERSION)
platforms = filter!(p -> arch(p) == "x86_64" || arch(p) == "aarch64", platforms)

platforms = expand_cxxstring_abis(platforms)
platforms = filter!(p -> cxxstring_abi(p) == "cxx11", platforms)

# platforms, mpi_dependencies = MPI.augment_platforms(platforms)
# filter!(p -> p["mpi"] ∉ ["mpitrampoline", "microsoftmpi"], platforms)

products = [
    LibraryProduct("liblegate", :liblegate)
] 


dependencies = [
    Dependency("HDF5_jll"; compat="~1.14.6"),
    Dependency("MPICH_jll"; compat="4.3.0"),
    Dependency("NCCL_jll"; compat="2.26.5"), # supports all of 12.x
    # Dependency("UCX_jll"),
    Dependency("Zlib_jll"; compat="1.2.12"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    HostBuildDependency(PackageSpec(; name = "CMake_jll", version = v"3.30.2")),
]

# append!(dependencies, mpi_dependencies)

for platform in platforms

    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform, static_sdk=true)

    cuda_ver = platform["cuda"]

    platform_sources = BinaryBuilder.AbstractSource[sources...]

    # Add x86_64 CUDA_SDK to cross compile for aarch64
    if arch(platform) == "aarch64"
        push!(platform_sources, CUDA.cuda_nvcc_redist_source(cuda_ver, "x86_64"))
    end

    clang_ver = VersionNumber(cuda_ver) >= v"12.6" ? v"17" : v"13"

    build_tarballs(ARGS, name, version, platform_sources, script, [platform],
                    products, [dependencies; cuda_deps];
                    julia_compat = "1.10", preferred_gcc_version = v"11",
                    preferred_llvm_version = clang_ver,
                    augment_platform_block=CUDA.augment,
                    lazy_artifacts = true, dont_dlopen = true
                )
    #augment_platform_block=augment_platform_block
end

