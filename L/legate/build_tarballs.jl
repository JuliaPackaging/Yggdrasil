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
    GitSource("https://github.com/nv-legate/legate.git", "40d29633519eb449e4a928bdc29cf0bd029707f8"),
]

MIN_CUDA_VERSION = v"12.0" #CUDA.full_version(v"12.0")

# REMOVE LATER
TEST_CUDA_VERSION = v"12.2"

# --build=${MACHTYPE} \
# --host=${target} \


# --build-march="${MARCH_FLAG}" \
# --with-hdf5 \
# --with-hdf5-dir=${prefix} \




script = raw"""

if [[ ${target} == x86_64-linux-musl ]]; then
    # HDF5 needs libcurl, and it needs to be the BinaryBuilder libcurl, not the system libcurl.
    # MPI needs libevent, and it needs to be the BinaryBuilder libevent, not the system libevent.
    rm /usr/lib/libcurl.*
    rm /usr/lib/libevent*
    rm /usr/lib/libnghttp2.*
fi

export PATH=${host_bindir}:$PATH

cd ${WORKSPACE}/srcdir
mkdir config_deps && cd config_deps
pip3 download --no-deps rich
pip3 download --no-deps typing_extensions
RICH_WHEEL=$(ls rich-*-py3-none-any.whl)
TYPE_EXT_WHEEL=$(ls typing_extensions-*-py3-none-any.whl)
unzip -q "$RICH_WHEEL" -d config_deps
unzip -q "$TYPE_EXT_WHEEL" -d config_deps

export PY_DEPS_DIR=$(pwd)/config_deps

PYTHONPATH="${PY_DEPS_DIR}" python3.10 -c "import rich, typing_extensions; print('Python deps installed and working!')"

cd ${WORKSPACE}/srcdir/legate

export CPPFLAGS="${CPPFLAGS} -I${prefix}/include"
export CFLAGS="${CFLAGS} -I${prefix}/include"
export LDFLAGS="${LDFLAGS} -L${prefix}/lib -L${prefix}/lib64"

export CUDA_HOME=${WORKSPACE}/destdir/cuda;
export PATH=$PATH:$CUDA_HOME/bin
export CUDACXX=$CUDA_HOME/bin/nvcc

# nvcc thinks the libraries are located inside lib64, but the SDK actually has them in lib
ln -s ${CUDA_HOME}/lib ${CUDA_HOME}/lib64

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

PYTHONPATH="${PY_DEPS_DIR}" python3.10 configure \
    --prefix=${prefix} \
    --with-cudac=${CUDACXX} \
    --with-cuda-dir=${CUDA_HOME} \
    --with-nccl-dir=${prefix} \
    --with-mpiexec-executable=${bindir}/mpiexec \
    --with-mpi-dir=${prefix} \
    --with-zlib-dir=${prefix} \
    --num-threads=${nproc} \
    --with-cxx=${CXX} \
    --with-cc=${CC} \
    --CXXFLAGS="${CPPFLAGS}" \
    --CFLAGS="${CFLAGS}" \

make install PREFIX=${prefix}
"""

platforms = CUDA.supported_platforms()
platforms = filter(p -> os(p) == "linux", platforms)
platforms = filter!(p -> arch(p) == "x86_64", platforms) #* could also support aarch64??
# platforms = filter!(p -> VersionNumber(tags(p)["cuda"]) >= MIN_CUDA_VERSION, platforms)

#* REMOVE LATER
platforms = filter!(p -> VersionNumber(tags(p)["cuda"]) == TEST_CUDA_VERSION, platforms)


#* TODO expand c-abi
#* TODO expand MPI?

products = [
    LibraryProduct("liblegate", :liblegate),
]

# CUDA SDK added later, see cuda_deps
dependencies = [
    Dependency("MPICH_jll"),
    Dependency("HDF5_jll"),
    Dependency("NCCL_jll"),
    Dependency("UCX_jll"),
    Dependency("Zlib_jll"),
    Dependency("OpenSSL_jll"),
    HostBuildDependency(PackageSpec(; name = "Python_jll", version = v"3.10.16")),
    HostBuildDependency(PackageSpec(; name = "CMake_jll", version = v"3.30.2"))
]

for platform in platforms

    should_build_platform(triplet(platform)) || continue

    # Suite Sparse has static_sdk = true
    # do we need that too? seems so
    cuda_deps = CUDA.required_dependencies(platform, static_sdk=true)

    build_tarballs(ARGS, name, version, sources, script, [platform],
                    products, [dependencies; cuda_deps];
                    julia_compat = "1.10", preferred_gcc_version = v"12",
                    augment_platform_block=CUDA.augment
                )

end