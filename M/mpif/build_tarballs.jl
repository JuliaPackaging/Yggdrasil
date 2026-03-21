using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

# Collection of sources required to build mpi-abi-stubs
name = "mpif"
version = v"0.1.5"

sources = [
    GitSource("https://github.com/eschnett/mpif", "9f13009bcbf15efe7c5362c416609a2a730ede84"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/mpif
cmake_args=(
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DBUILD_SHARED_LIBS=ON
    -DMPI_HOME=${prefix}
)
cmake -Bbuild ${cmake_args[@]}
cmake --build build --parallel ${nproc}
cmake --install build
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
    """

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)
platforms, platform_dependencies = MPI.augment_platforms(platforms)

# We only build for the MPI ABI
filter!(p -> p["mpi"] == "mpiabi", platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]
append!(dependencies, platform_dependencies)

# The products that we will ensure are always built.
products = [
    LibraryProduct("libmpif", :libmpif),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6")
