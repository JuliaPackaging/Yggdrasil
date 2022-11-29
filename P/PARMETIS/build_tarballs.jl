using BinaryBuilder
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "PARMETIS"
version = v"4.0.5" # <-- This is a lie, we're bumping to 4.0.5 since we are adding new dependencies
parmetis_version = v"4.0.3"

# Collection of sources required to build PARMETIS.
# The patch prevents building the source of METIS that ships with PARMETIS;
# we rely on METIS_jll instead.
sources = [
    ArchiveSource("http://glaros.dtc.umn.edu/gkhome/fetch/sw/parmetis/parmetis-$(parmetis_version).tar.gz",
                  "f2d9a231b7cf97f1fee6e8c9663113ebf6c240d407d3c118c55b3633d6be6e5f"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${libdir}
cd $WORKSPACE/srcdir/parmetis-4.0.3

for f in ${WORKSPACE}/srcdir/patches/*.patch; do
  atomic_patch -p1 ${f}
done

grep -iq MPICH $prefix/include/mpi.h && mpi_libraries='mpi'
grep -iq MPItrampoline $prefix/include/mpi.h && mpi_libraries='mpitrampoline'
grep -iq OpenMPI $prefix/include/mpi.h && mpi_libraries='mpi'

cd build
# {1} is inttype (32 or 64) and {2} is realtype (32 or 64)
build_parmetis()
{
    if [ "${1}" == "32" ] && [ "${2}" == "32" ]; then
        PARMETIS_NAME=parmetis
        METIS_NAME=metis
        METIS_PATH="${prefix}"
    else
        METIS_NAME="metis_Int${1}_Real${2}"
        PARMETIS_NAME="par${METIS_NAME}"
        METIS_PATH="${libdir}/metis/${METIS_NAME}"
    fi
    cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DSHARED=1 \
    -DGKLIB_PATH=$(realpath ../metis/GKlib) \
    -DMETIS_PATH="${METIS_PATH}" \
    -DMPI_INCLUDE_PATH="${prefix}/include" \
    -DMPI_LIBRARIES="${mpi_libraries}" \
    -DCMAKE_C_FLAGS="-DIDXTYPEWIDTH=${1} -DREALTYPEWIDTH=${2}" \
    -DBINARY_NAME="${PARMETIS_NAME}" \
    -DMETIS_LIBRARY="${METIS_NAME}"
    
    make -j${nproc}
    make install
}

build_parmetis 32 32
build_parmetis 32 64
build_parmetis 64 32
build_parmetis 64 64
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# OpenMPI and MPICH are not precompiled for Windows
platforms = supported_platforms(; exclude=Sys.iswindows)

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libparmetis", :libparmetis),
    LibraryProduct("libparmetis_Int32_Real64", :libparmetis_Int32_Real64),
    LibraryProduct("libparmetis_Int64_Real32", :libparmetis_Int64_Real32),
    LibraryProduct("libparmetis_Int64_Real64", :libparmetis_Int64_Real64)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("METIS_jll"; compat="5.1.2"),
]
append!(dependencies, platform_dependencies)

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"8")
