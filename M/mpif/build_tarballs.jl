using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

# Collection of sources required to build mpi-abi-stubs
name = "mpif"
version = v"1.0.0"

sources = [
    GitSource("https://github.com/eschnett/mpif", "9caecc3ce4f4eabad27dad4e1dae05ff7df21b32"),
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
# mpif's callback registry uses C11 atomics, and on AArch64 clang turns an
# acq_rel compare-exchange into a call to __aarch64_cas4_acq_rel. That helper
# is in compiler-rt's builtins or in libgcc >= 10, and neither is on the link
# line: libmpif has Fortran sources, so CMake links it with gfortran, whose
# libgcc here is GCC 9.1's. Inline the atomics instead -- they are cold.
# https://github.com/eschnett/mpif/issues/5 -- drop this once mpif probes for it.
if [[ "${target}" == aarch64-*freebsd* ]]; then
    cmake_args+=(-DCMAKE_C_FLAGS=-mno-outline-atomics)
fi
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
# mpif requires at least gfortran 8
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"8")
