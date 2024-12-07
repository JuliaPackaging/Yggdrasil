# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "HYPRE"
version = v"2.23.1"
hypre_version = v"2.23.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/hypre-space/hypre/archive/refs/tags/v$(hypre_version).tar.gz",
                  "8a9f9fb6f65531b77e4c319bf35bfc9d34bf529c36afe08837f56b635ac052e2")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/hypre-*
cd src

mkdir build
cd build

CMAKE_FLAGS=()

#help find mpi on mingw, subset of https://github.com/JuliaPackaging/Yggdrasil/blob/b4fdb545c3954cff218051d7520c7418991d3416/T/TauDEM/build_tarballs.jl#L28-L53
if [[ "$target" == x86_64-w64-mingw32 ]]; then
    CMAKE_FLAGS+=(
        -DMPI_HOME=${prefix}
        -DMPI_GUESS_LIBRARY_NAME=MSMPI
    )
    if [[ "${target}" == x86_64-* ]]; then
        for lang in C CXX; do
            CMAKE_FLAGS+=(-DMPI_${lang}_LIBRARIES=msmpi64)
        done
    fi
fi

cmake .. \
-DCMAKE_INSTALL_PREFIX=$prefix \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release \
-DHYPRE_ENABLE_SHARED=ON \
-DHYPRE_ENABLE_HYPRE_BLAS=ON \
-DHYPRE_ENABLE_HYPRE_LAPACK=ON \
-DHYPRE_ENABLE_CUDA_STREAMS=OFF \
-DHYPRE_ENABLE_CUSPARSE=OFF \
-DHYPRE_ENABLE_CURAND=OFF \
"${CMAKE_FLAGS[@]}"

make -j${nproc}
make install
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libHYPRE", :libHYPRE)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS_jll", uuid="4536629a-c528-5b80-bd46-f80d51c5b363")),
    Dependency(PackageSpec(name="LAPACK_jll", uuid="51474c39-65e3-53ba-86ba-03b1b862ec14")),
]
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version = v"8")
