using BinaryBuilder
import Pkg: PackageSpec

# Heavily Copies from: https://github.com/JuliaPackaging/Yggdrasil/blob/master/S/SuiteSparse/SuiteSparse_GPU%407/build_tarballs.jl

const YGGDRASIL_DIR = "../../"
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "legate"
version = v"25.03"
sources = [
    GitSource("https://github.com/nv-legate/legate.git", "40d29633519eb449e4a928bdc29cf0bd029707f8"),
]

CUDA_VERSION = CUDA.full_version(v"12.2")
# CUDA_VERSION = CUDA.full_version(v"11.8")

script = raw"""
cd ${WORKSPACE}/srcdir/legate

export CPPFLAGS="${CPPFLAGS} -I${prefix}/include"
export CLFAGS="${CLFAGS} -I${prefix}/include"
export LDFLAGS="${LDFLAGS} -L${prefix}/lib -L${prefix}/lib64"

export PATH=${host_bindir}/python3.10:$PATH

python3.10 configure \
    --prefix=$prefix \
    --build=${MACHTYPE} \
    --host=${target} \
    --build-march=${target%%-*} \
    --with-cuda \
    --with-cudac=${bindir}/cuda/nvcc \
    --with-cuda-dir=${prefix} \
    --with-nccl \
    --with-nccl-dir=${prefix} \
    --with-hdf5=0 \
    --with-mpi \
    --with-mpiexec-executable=${bindir}/mpiexec \
    --with-mpi-dir=${prefix} \
    --with-zlib \
    --with-zlib-dir=${prefix} \
    --num-threads=${nproc} \
    --with-cxx=${CXX} \
    --with-cc=${CC} \
    --CXXFLAGS=${CPPFLAGS} \
    --CFLAGS=${CFLAGS} \

make install PREFIX=${prefix}
"""

# platforms = CUDA.supported_platforms()

platforms = [Platform("x86_64", "linux")]

#*TODO expand c-abi

products = [
    LibraryProduct("liblegate", :liblegate),
]


dependencies = [
    Dependency("MPICH_jll"),
    Dependency("NCCL_jll"),
    Dependency("UCX_jll"),
    Dependency("Zlib_jll"),
    Dependency("CUDA_SDK_jll", CUDA_VERSION), #* PROBABLY BETTER TO DEFINE A COMPAT FOR >= 12.0
    HostBuildDependency(PackageSpec(; name = "Python_jll", version = v"3.10.16"))
]

for platform in platforms

    should_build_platform(triplet(platform)) || continue

    # Suite Sparse has static_sdk = true
    cuda_deps = CUDA.required_dependencies(platform, static_sdk=false)

    build_tarballs(ARGS, name, version, sources, script, [platform],
                    products, [dependencies; cuda_deps];
                    julia_compat = "1.10", preferred_gcc_version = v"13",
                    augment_platform_block=CUDA.augment)

end