# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "HYPRE"
version = v"3.0.0"
hypre_version = v"3.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/hypre-space/hypre.git", "da9f93f8d698f4caaaff35fe81655b8ad7bb91f9") # Tag v3.0.0
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/hypre
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
-DBUILD_SHARED_LIBS=ON \
-DHYPRE_ENABLE_HYPRE_BLAS=ON \
-DHYPRE_ENABLE_HYPRE_LAPACK=ON \
-DHYPRE_ENABLE_CUDA_STREAMS=OFF \
-DHYPRE_ENABLE_CUSPARSE=OFF \
-DHYPRE_ENABLE_CURAND=OFF \
-DHYPRE_ENABLE_OPENMP=ON \
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
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libHYPRE", :libHYPRE)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS_jll", uuid="4536629a-c528-5b80-bd46-f80d51c5b363")),
    Dependency(PackageSpec(name="LAPACK_jll", uuid="51474c39-65e3-53ba-86ba-03b1b862ec14")),
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms))
]
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version = v"8")
