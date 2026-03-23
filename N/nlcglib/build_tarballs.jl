# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "nlcglib"
version = v"1.1.0"
ygg_version = v"1.1.1"          # we bumped the version to update MPI compat bounds

sources = [
   GitSource("https://github.com/simonpintarelli/nlcglib/", "674039fd2b131ce12d46d105b437265419999197")
]

script = raw"""
cd $WORKSPACE/srcdir

CMAKE_ARGS=(
    -DUSE_OPENMP=ON
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DCMAKE_FIND_ROOT_PATH=${prefix}
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_BUILD_TYPE=Release
    -DMPI_C_COMPILER=${bindir}/mpicc
    -DMPI_CXX_COMPILER=${bindir}/mpicxx
)

cmake -B build ${CMAKE_ARGS[@]}
cmake --build build --parallel ${nproc}
cmake --install build
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

platforms = supported_platforms()                                                       
filter!(!Sys.iswindows, platforms)
platforms = expand_cxxstring_abis(platforms)
#Apply same restriction as Kokkos
filter!(p -> nbits(p) != 32, platforms)

products = [
   LibraryProduct("libnlcglib", :libnlcglib)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenBLAS32_jll"),
    Dependency("Kokkos_jll"; compat="~4.7.1"), # Kokkos does not guarantee ABI stability across minor versions
    BuildDependency("nlohmann_json_jll"),
    Dependency("CompilerSupportLibraries_jll", platforms=filter(!Sys.isapple, platforms)),
    Dependency("LLVMOpenMP_jll", platforms=filter(Sys.isapple, platforms))
]

platforms, platform_dependencies = MPI.augment_platforms(platforms)
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.10", preferred_gcc_version=v"9")
