using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "HelloWorldMPIC"
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
cmake -Bbuild ${cmake_args[@]}
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

platforms = supported_platforms()
platforms, dependencies = MPI.augment_platforms(platforms)

products = [
    ExecutableProduct("hello_world", :hello_world),
]

# Keep MPItrampoline from loading `mpiwrapper.so` when the audit dlopens the products.
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

# The MPI JLLs ship only libgfortran5 builds, which GCC 8 or newer selects.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"8")
