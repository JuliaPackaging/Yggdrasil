using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "PARMETIS"
version = v"4.0.6" # <-- This is a lie, we're bumping to 4.0.6 since we are adding new dependencies and building all library versions.
parmetis_version = v"4.0.3"

# Collection of sources required to build PARMETIS.
# The patch prevents building the source of METIS that ships with PARMETIS;
# we rely on METIS_jll instead.
sources = [
    ArchiveSource("https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/parmetis/4.0.3-4/parmetis_4.0.3.orig.tar.gz",
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

pushd metis
if [ $target = "x86_64-w64-mingw32" ] || [ $target = "i686-w64-mingw32" ]; then
    atomic_patch -p1 $WORKSPACE/srcdir/metis_patches/0001-mingw-w64-does-not-have-sys-resource-h.patch
    atomic_patch -p1 $WORKSPACE/srcdir/metis_patches/0002-mingw-w64-do-not-use-reserved-double-underscored-names.patch
    atomic_patch -p1 $WORKSPACE/srcdir/metis_patches/0003-WIN32-Install-RUNTIME-to-bin.patch
    atomic_patch -p1 $WORKSPACE/srcdir/metis_patches/0004-Fix-GKLIB_PATH-default-for-out-of-tree-builds.patch
fi
popd

grep -iq MPICH $prefix/include/mpi.h && mpi_libraries='mpi'
grep -iq OMPI $prefix/include/mpi.h && mpi_libraries='mpi'
grep -iq MSMPI $prefix/include/mpi.h && mpi_libraries='msmpi'
grep -iq MPItrampoline $prefix/include/mpi.h && mpi_libraries='mpitrampoline'

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

install_license ../LICENSE.txt
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

platforms = supported_platforms()
platforms, platform_dependencies = MPI.augment_platforms(platforms; MPItrampoline_compat="5.2.1", OpenMPI_compat="4.1.6, 5")

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
    Dependency(PackageSpec(name="METIS_jll", uuid="d00139f3-1899-568f-a2f0-47f597d42d70"); compat="5.1.2"),
]
append!(dependencies, platform_dependencies)

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"8")
