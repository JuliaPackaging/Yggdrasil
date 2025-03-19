using BinaryBuilder
import Pkg: PackageSpec

name = "legate"
version = v"25.03"
sources = [
    GitSource("https://github.com/nv-legate/legate.git", "40d29633519eb449e4a928bdc29cf0bd029707f8"),
]

# needed at runtime??
# apk add numactl

script = raw"""
cd ${WORKSPACE}/srcdir/legate

export CPPFLAGS="${CPPFLAGS} -I${prefix}/include"
export CLFAGS="${CLFAGS} -I${prefix}/include"
export LDFLAGS="${LDFLAGS} -L${prefix}/lib -L${prefix}/lib64"

./configure \
    --prefix=$prefix \
    --build=${MACHTYPE} \
    --host=${target} \
    --with-cuda \
    --with-cuda-dir=${prefix} \
    --with-nccl \
    --with-nccl-dir=${prefix} \
    --with-mpi \
    --with-mpi-dir=${prefix} \
    --with-hdf5 \
    --with-hdf5-dir=${prefix} \
    --with-zlib \
    --with-zlib-dir=${prefix} \
    --num-threads=${nproc} \
    --with-cxx=${CXX} \
    --with-cc=${CC} \
    --CXXFLAGS=${CPPFLAGS} \
    --CFLAGS=${CFLAGS} \

make install PREFIX=${prefix}
"""

platforms = [Platform("x86_64", "linux")]
# platforms = supported_platforms()

#*TODO expand c-abi

products = [
    LibraryProduct("liblegate", :liblegate),
]

#* nvcc as BuildDependency?
#* CUDA Toolkit as actual dependency?
# pyhton is needed cause BinaryBuilder env only has 3.9.8 and
# configure script wants 3.10
dependencies = [
    Dependency("MPICH_jll"),
    Dependency("CUDA_jll"),
    Dependency("NCCL_jll"),
    Dependency("HDF5_jll"),
    Dependency("Zlib_jll"),
    BuildDependency(PackageSpec(; name = "Python_jll", version = v"3.10.16"))
]

build_tarballs(ARGS, name, version, sources, script, platforms,
                 products, dependencies, preferred_gcc_version = v"13")