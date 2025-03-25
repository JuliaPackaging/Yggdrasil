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

# --build=${MACHTYPE} \
# --host=${target} \

script = raw"""

export PATH=${host_bindir}/python3.10:$PATH

cd ${WORKSPACE}/srcdir
mkdir config_deps && cd config_deps
pip3 download --no-deps rich
pip3 download --no-deps typing_extensions
RICH_WHEEL=$(ls rich-*-py3-none-any.whl)
TYPE_EXT_WHEEL=$(ls typing_extensions-*-py3-none-any.whl)
unzip -q "$RICH_WHEEL" -d config_deps
unzip -q "$TYPE_EXT_WHEEL" -d config_deps

export PY_DEPS_DIR=$(pwd)

PYTHONPATH="${PY_DEPS_DIR}/config_deps" python3.10 -c "import rich, typing_extensions; print('Python deps installed and working!')"

cd ${WORKSPACE}/srcdir/legate

export CPPFLAGS="${CPPFLAGS} -I${prefix}/include"
export CLFAGS="${CLFAGS} -I${prefix}/include"
export LDFLAGS="${LDFLAGS} -L${prefix}/lib -L${prefix}/lib64"

PYTHONPATH="${PY_DEPS_DIR}/config_deps" python3.10 configure \
    --prefix=$prefix \
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
    # HostBuildDependency(PackageSpec(; name = "Expat_jll")),
    HostBuildDependency(PackageSpec(; name = "Python_jll", version = v"3.10.16"))
]

for platform in platforms

    should_build_platform(triplet(platform)) || continue

    # Suite Sparse has static_sdk = true
    cuda_deps = CUDA.required_dependencies(platform, static_sdk=false)

    build_tarballs(ARGS, name, version, sources, script, [platform],
                    products, [dependencies; cuda_deps];
                    julia_compat = "1.10", preferred_gcc_version = v"13",
                    augment_platform_block=CUDA.augment
                )

end