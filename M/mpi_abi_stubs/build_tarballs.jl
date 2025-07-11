using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

# Collection of sources required to build mpi-abi-stubs
name = "mpi_abi_stubs"
# There are no released versions. We choose a recent commit.
# This corresponds to the MPI standard 5.0.
# Let's keep the major/minor version numbers corresponding to the MPI standard,
# and use the patch number for minor updates.
version = v"5.0.0"

sources = [
    GitSource("https://github.com/mpi-forum/mpi-abi-stubs", "6bc15b268d3c780259294ebea9ebaf11bdf8680a"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/mpi-abi-stubs
cmake_args=(
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_PREFIX_PATH=${prefix}
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

# Add `mpi+mpiabi` platform tag
for p in platforms
    p["mpi"] = "MPIABI"
end

# Dependencies that must be installed before this package can be built
dependencies = [
    RuntimeDependency(PackageSpec(name="MPIPreferences", uuid="3da0fdf6-3ccc-4f1b-acd9-58baa6c99267");
                      compat="0.1", top_level=true),
]

# The products that we will ensure are always built.
products = [
    LibraryProduct("libmpi_abi", :libmpi_abi),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6")
