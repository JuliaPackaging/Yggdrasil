using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "HelloWorldMPIFortran"
version = v"1.0.0"

# No sources, we're just building the testsuite
sources = [
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/files

# This would work as well
# mpifort -o ${bindir}/hello_world${exeext} -g -O2 ${WORKSPACE}/srcdir/files/hello_world.F90

cmake_args=(
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DMPI_HOME=${prefix}
)
cmake -Bbuild ${cmake_args[@]}
cmake --build build --parallel ${nproc}
cmake --install build

install_license /usr/share/licenses/MIT

# Run the executable if we built for the host platform
if [[ ${rust_host} == ${rust_target} ]]; then
    mpiexec -n 2 ${bindir}/hello_world${exeext}
fi
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

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]
append!(dependencies, platform_dependencies)

# The products that we will ensure are always built
products = [
    ExecutableProduct("hello_world", :hello_world),
]

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and
# `dlopen`s the shared libraries. (MPItrampoline will skip its
# automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"5")
