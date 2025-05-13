using BinaryBuilder
import Pkg: PackageSpec
using Base.BinaryPlatforms: arch, os, tags

# Heavily Copies from: https://github.com/JuliaPackaging/Yggdrasil/blob/master/S/SuiteSparse/SuiteSparse_GPU%407/build_tarballs.jl

const YGGDRASIL_DIR = "../../"
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "legate"
version = v"25.03"
sources = [
    GitSource("https://github.com/nv-legate/legate.git","8a619fa468a73f9766f59ac9a614c0ee084ecbdd")
    # GitSource("https://github.com/nv-legate/legate.git", "1478fa09e7e3cb6b177bef0aae74cd04c3a43417"),
]

MIN_CUDA_VERSION = v"12.0" #CUDA.full_version(v"12.0")
TEST_CUDA_VERSION = v"12.8" # REMOVE LATER

# --build-march="${MARCH_FLAG}" \

# HDF5 needs libcurl, and it needs to be the BinaryBuilder libcurl, not the system libcurl.
#     rm /usr/lib/libcurl.*

# --build-type="debug" \


script = raw"""

if [[ ${target} == x86_64-linux-musl ]]; then
    # MPI needs libevent, and it needs to be the BinaryBuilder libevent, not the system libevent.
    rm /usr/lib/libevent*
    rm /usr/lib/libnghttp2.*
fi

# Put new CMake first on path
export PATH=${host_bindir}:$PATH

# Install Python 3.11
wget https://repo.anaconda.com/miniconda/Miniconda3-py311_24.3.0-0-Linux-x86_64.sh -O miniconda.sh
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

### Parse march flag

MARCH_FLAG=""

case "${target%%-*}" in
  x86_64)
  MARCH_FLAG="x86-64"
  ;;
  aarch64)
  MARCH_FLAG="armv8-a"
  ;;
  *)
    echo "Error: Unknown architecture, '${target%%-*}'"
    exit 1
esac

#--with-nccl-dir=${prefix} \
# --with-cxx=${CXX} \
# --with-cc=${CC} \
# --with-cxx=clang++ \
# --with-cc=clang \
#--with-hdf5-vfd-gds=0 \


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
    --with-hdf5=0 \
    --num-threads=${nproc} \
    --with-cxx=${CXX} \
    --with-cc=${CC} \
    --CXXFLAGS="${CPPFLAGS}" \
    --CFLAGS="${CFLAGS}" \
    --with-clean \
    --cmake-executable=${host_bindir}/cmake \
    -- "-DCMAKE_TOOLCHAIN_FILE=/opt/toolchains/${bb_full_target}/target_${target}_clang.cmake"


make install -j ${nproc} PREFIX=${prefix}
"""

platforms = CUDA.supported_platforms()
platforms = filter(p -> os(p) == "linux", platforms)
platforms = filter!(p -> arch(p) == "x86_64", platforms) #* could also support aarch64??
# platforms = filter!(p -> VersionNumber(tags(p)["cuda"]) >= MIN_CUDA_VERSION, platforms)

#* REMOVE LATER
platforms = filter!(p -> VersionNumber(tags(p)["cuda"]) == TEST_CUDA_VERSION, platforms)

print(platforms)

#* TODO expand c-abi
#* TODO expand MPI abi

products = [
    LibraryProduct("liblegate", :liblegate),
    LibraryProduct("liblegion-legate", :liblegionlegate),
    LibraryProduct("librealm-legate", :librealmlegate),
    LibraryProduct("libcpptrace", :libcpptrace),
]

# CUDA SDK added later, see cuda_deps
dependencies = [
    Dependency("MPICH_jll"),
    Dependency("HDF5_jll"),
    # Dependency("NCCL_jll"),
    Dependency("UCX_jll"),
    Dependency("Zlib_jll"),
    Dependency("OpenSSL_jll"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    BuildDependency(PackageSpec(; name = "Clang_jll", version = v"v20.1.2")),
    HostBuildDependency(PackageSpec(; name = "CMake_jll", version = v"3.30.2")),
]

for platform in platforms

    should_build_platform(triplet(platform)) || continue

    # Suite Sparse has static_sdk = true
    # do we need that too? seems so
    cuda_deps = CUDA.required_dependencies(platform, static_sdk=true)

    build_tarballs(ARGS, name, version, sources, script, [platform],
                    products, [dependencies; cuda_deps];
                    julia_compat = "1.10", preferred_gcc_version = v"13",
                    augment_platform_block=CUDA.augment
                )

end
