using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "HelloWorldMPIFortran"
version = v"1.0.2"

sources = [
    DirectorySource("bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/files

cmake_args=(
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DMPI_HOME=${prefix}
)
if [[ ${target} == *-mingw* ]]; then
    # As in H/HDF5: gfortran cannot link MS-MPI's Fortran wrapper library, but msmpi.dll
    # exports the gfortran-mangled entry points; mpif.h needs -fallow-invalid-boz.
    # Setting MPI_Fortran_INCLUDE_DIRS skips FindMPI's failing check but does not reach
    # the compile line, so mpi.mod needs its own -I.
    cmake_args+=(
        -DMPI_GUESS_LIBRARY_NAME=MSMPI
        -DMPI_Fortran_LIBRARIES=${libdir}/msmpi.${dlext}
        -DMPI_Fortran_INCLUDE_DIRS=${includedir}
        -DCMAKE_Fortran_FLAGS="-fallow-invalid-boz -I${includedir}"
    )
fi
cmake -Bbuild "${cmake_args[@]}"
cmake --build build --parallel ${nproc}
cmake --install build

install_license /usr/share/licenses/MIT

# Smoke test on the one target the build host can run. Not usually part of a recipe.
if [[ ${target} == x86_64-linux-musl ]]; then
    # OpenMPI needs ssh and refuses to run as root by default
    apk add openssh-client
    export OMPI_ALLOW_RUN_AS_ROOT=1
    export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
    mpiexec -n 2 ${bindir}/hello_world${exeext}
fi
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
    """

platforms = expand_gfortran_versions(supported_platforms())
platforms, dependencies = MPI.augment_platforms(platforms)

append!(dependencies, [
    Dependency("CompilerSupportLibraries_jll"; compat="1.0.5"),
    # MPIABI provides only the C bindings
    Dependency("mpif_jll"; compat="1.0.1", platforms=filter(p -> p["mpi"] == "mpiabi", platforms)),
])

products = [
    ExecutableProduct("hello_world", :hello_world),
]

# Keep MPItrampoline from loading `mpiwrapper.so` when the audit dlopens the products.
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

# -fallow-invalid-boz needs GCC 10; the MPICH Fortran bindings need at least GCC 9.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"10")
