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
    GitSource("https://github.com/nv-legate/legate.git","98e78b221f02bf3d04dbe22518e1bf3033bf1f8b")
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

### Install Python Dependencies in a Really Stupid Way

cd ${WORKSPACE}/srcdir
mkdir config_deps && cd config_deps
pip3 download --no-deps rich
pip3 download --no-deps typing_extensions
pip3 download --no-deps packaging
RICH_WHEEL=$(ls rich-*-py3-none-any.whl)
TYPE_EXT_WHEEL=$(ls typing_extensions-*-py3-none-any.whl)
PACKAGING_WHEEL=$(ls packaging-*-py3-none-any.whl)
unzip -q "$RICH_WHEEL" -d config_deps
unzip -q "$TYPE_EXT_WHEEL" -d config_deps
unzip -q "$PACKAGING_WHEEL" -d config_deps

pip3 download --no-deps git+https://github.com/nv-legate/aedifix@1.2.0
unzip aedifix-*

export PY_DEPS_DIR=$(pwd)/config_deps:$(pwd)/config_deps/aedifix/src/aedifix

PYTHONPATH="${PY_DEPS_DIR}" python3.10 -c "import rich, typing_extensions, packaging, aedifix; print('Python deps installed and working!')"

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

export PYTHONPATH="${PY_DEPS_DIR}"

sed -i "1s|#\!/usr/bin/env python3|#\!${host_bindir}/python3.10|" configure


#--with-nccl-dir=${prefix} \
# --with-cxx=${CXX} \
# --with-cc=${CC} \
# --with-cxx=clang++ \
# --with-cc=clang \

./configure \
    --prefix=${prefix} \
    --with-cudac=${CUDACXX} \
    --with-cuda-dir=${CUDA_HOME} \
    --with-nccl=0 \
    --with-mpiexec-executable=${bindir}/mpiexec \
    --with-mpi-dir=${prefix} \
    --with-zlib-dir=${prefix} \
    --with-hdf5=0 \
    --with-hdf5-vfd-gds=0 \
    --num-threads=1 \
    --with-cxx=${CXX} \
    --with-cc=${CC} \
    --CXXFLAGS="${CPPFLAGS}" \
    --CFLAGS="${CFLAGS}" \
    --with-clean \
    --cmake-executable=${host_bindir}/cmake \
    -- "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}"

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
    HostBuildDependency(PackageSpec(; name = "Python_jll", version = v"3.10.16"))
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
