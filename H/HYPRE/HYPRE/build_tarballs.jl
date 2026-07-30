using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "HYPRE"
version = v"3.1.0"
ygg_version = v"3.1.1"

sources = [
    GitSource("https://github.com/hypre-space/hypre.git", "9dc9e18aed6a945a95f966e57daacfb1c269f6ec") # Tag v3.1.0
]

script = raw"""
cd $WORKSPACE/srcdir/hypre/src

if [[ "${target}" == *mingw* ]]; then
    LBT=(-lblastrampoline-5)
else
    LBT=(-lblastrampoline)
fi

MPI_SETTINGS=(-DMPI_HOME=${prefix})
if [[ "${target}" == x86_64-w64-mingw32 ]]; then
    MPI_SETTINGS+=(
        -DMPI_GUESS_LIBRARY_NAME=MSMPI
        -DMPI_C_LIBRARIES=msmpi64
        -DMPI_CXX_LIBRARIES=msmpi64
    )
fi

mkdir build
cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DHYPRE_ENABLE_HYPRE_BLAS=OFF \
    -DHYPRE_ENABLE_HYPRE_LAPACK=OFF \
    -DTPL_BLAS_LIBRARIES="${LBT[*]}" \
    -DTPL_LAPACK_LIBRARIES="${LBT[*]}" \
    -DHYPRE_ENABLE_OPENMP=ON \
    -DHYPRE_ENABLE_CUDA_STREAMS=OFF \
    -DHYPRE_ENABLE_CUSPARSE=OFF \
    -DHYPRE_ENABLE_CURAND=OFF \
    "${MPI_SETTINGS[@]}"

make -j${nproc}
make install
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

platforms = supported_platforms()
platforms, platform_dependencies = MPI.augment_platforms(platforms)

products = [
    LibraryProduct("libHYPRE", :libHYPRE)
]

dependencies = [
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"); compat="5.4.0"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms=filter(Sys.isbsd, platforms))
]
append!(dependencies, platform_dependencies)

build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.10", preferred_gcc_version = v"8")
