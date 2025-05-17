using BinaryBuilder
import Pkg: PackageSpec
using Base.BinaryPlatforms: arch, os, tags

# Heavily Copies from: https://github.com/JuliaPackaging/Yggdrasil/blob/master/S/SuiteSparse/SuiteSparse_GPU%407/build_tarballs.jl

const YGGDRASIL_DIR = "../../"
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "legate"
version = v"25.03"
sources = [
    GitSource("https://github.com/nv-legate/legate.git","8a619fa468a73f9766f59ac9a614c0ee084ecbdd"),
    FileSource("https://repo.anaconda.com/miniconda/Miniconda3-py311_24.3.0-0-Linux-x86_64.sh", 
                "4da8dde69eca0d9bc31420349a204851bfa2a1c87aeb87fe0c05517797edaac4", "miniconda.sh")
]

MIN_CUDA_VERSION = v"12.0" #* Try down to 12.0
MAX_CUDA_VERSION = v"12.8.999"


script = raw"""

if [[ ${target} == x86_64-linux-musl ]]; then
    # HDF5 needs libcurl, and it needs to be the BinaryBuilder libcurl, not the system libcurl.
    # MPI needs libevent, and it needs to be the BinaryBuilder libevent, not the system libevent.
    rm /usr/lib/libcurl.*
    rm /usr/lib/libevent*
    rm /usr/lib/libnghttp2.*
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

# nvcc thinks the libraries are located inside lib64, but the SDK actually has them in lib
ln -s ${CUDA_HOME}/lib ${CUDA_HOME}/lib64

export CC="clang"
export CXX="clang++"
export BUILD_CXX=$(which clang++)
export BUILD_CC=$(which clang)

./configure \
    --prefix=${prefix} \
    --with-cudac=${CUDACXX} \
    --with-cuda-dir=${CUDA_HOME} \
    --with-nccl=0 \
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


make install -j ${nproc} PREFIX=${prefix}
install_license ${WORKSPACE}/srcdir/legate/LICENSE
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
platforms = filter(p -> os(p) == "linux", platforms)
# platforms = filter!(p -> arch(p) == "x86_64" || arch(p) == "aarch64", platforms)
platforms = filter!(p -> arch(p) == "x86_64", platforms)

# platforms = filter!(p -> tags(p)["cuda_platform"] != "jetson", platforms) # build for jetson??

#* REMOVE LATER
# platforms = filter!(p -> VersionNumber(tags(p)["cuda"]) == v"12.8", platforms)

platforms = expand_cxxstring_abis(platforms)
platforms = filter!(p -> cxxstring_abi(p) == "cxx11", platforms)

# platforms, mpi_dependencies = MPI.augment_platforms(platforms)
# filter!(p -> p["mpi"] ∉ ["mpitrampoline", "microsoftmpi"], platforms)

# print(platforms)

# platforms = [platforms[1]]

# also some warnings about avx2 instruction set vs x86_64
# dont_dlopen avoids version `GLIBCXX_3.4.30' not found
products = [
    LibraryProduct("liblegate", :liblegate, dont_dlopen = true)
] 

dependencies = [
    Dependency("HDF5_jll"; compat="~1.14.6"),
    Dependency("MPICH_jll"; compat="~4.3.0"),
    # Dependency("NCCL_jll"),
    # Dependency("UCX_jll"),
    Dependency("Zlib_jll"; compat="~1.3.1"),
    Dependency(PackageSpec(; name="CUDA_Driver_jll"); compat = "~0.13.0"), # compat to prevent use of CUDA 13.x drivers in the future
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    HostBuildDependency(PackageSpec(; name = "CMake_jll", version = v"3.30.2")),
]

# append!(dependencies, mpi_dependencies)

for platform in platforms

    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform, static_sdk=true)


    cuda_ver = VersionNumber(tags(platform)["cuda"])

    clang_ver = cuda_ver >= v"12.6" ? v"17" : v"13"

    build_tarballs(ARGS, name, version, sources, script, [platform],
                    products, [dependencies; cuda_deps];
                    julia_compat = "1.10", preferred_gcc_version = v"12",
                    preferred_llvm_version = clang_ver, # clang 13 works for all CUDA 12.x
                    augment_platform_block=CUDA.augment, lazy_artifacts = true
                )
    #augment_platform_block=augment_platform_block
end

