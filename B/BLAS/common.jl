using BinaryBuilder, Pkg

# BLAS mirrors the OpenBLAS build, whereas BLAS32 mirrors the OpenBLAS32 build.

version = v"3.11.0"

# Collection of sources required to build lapack
sources = [
    ArchiveSource("http://www.netlib.org/blas/blas-3.11.0.tgz",
                  "2d9fdee7d361954fee532100a50e602826c9cc1153f8cd057baa65ed57e90283"),
]

# Bash recipe for building across all platforms

function blas_script(;blas32::Bool=false)
script = "BLAS32=$(blas32)"

script *= raw"""
if [[ ${nbits} == 64 ]] && [[ "${BLAS32}" != "true" ]]; then
    ILP64="ON"
else
    ILP64="OFF"
fi

cd BLAS-*
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$prefix \
         -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
         -DCMAKE_BUILD_TYPE=Release \
         -DBUILD_SHARED_LIBS=ON \
         -DBUILD_INDEX64=${ILP64}

make
make install
"""
end

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]
