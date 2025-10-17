using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "MUMPS"
version = v"5.8.1"

sources = [
  ArchiveSource("https://mumps-solver.org/MUMPS_$(version).tar.gz",
                "e91b6dcd93597a34c0d433b862cf303835e1ea05f12af073b06c32f652f3edd8")
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${libdir}
cd $WORKSPACE/srcdir/MUMPS*

makefile="Makefile.G95.PAR"
cp Make.inc/${makefile} Makefile.inc

# Add `-fallow-argument-mismatch` if supported
: >empty.f
if gfortran -c -fallow-argument-mismatch empty.f >/dev/null 2>&1; then
    FFLAGS=("-fallow-argument-mismatch")
fi
rm -f empty.*

if [[ "${target}" == *apple* ]]; then
    SONAME="-install_name"
else
    SONAME="-soname"
fi

MPILIBS=()
if grep -q MSMPI "${includedir}/mpi.h"; then
    MPILIBS=(-lmsmpi)
elif grep -q MPICH "${includedir}/mpi.h"; then
    MPILIBS=(-lmpifort -lmpi)
elif grep -q MPItrampoline "${includedir}/mpi.h"; then
    MPILIBS=(-lmpitrampoline)
elif grep -q OMPI_MAJOR_VERSION "${includedir}/mpi.h"; then
    MPILIBS=(-lmpi_usempif08 -lmpi_usempi_ignore_tkr -lmpi_mpifh -lmpi)
fi

# Override MPItrampoline's built-in compiler paths
export MPITRAMPOLINE_CC=cc
export MPITRAMPOLINE_CXX=c++
export MPITRAMPOLINE_FC=gfortran

if [[ "${target}" == *mingw32* ]]; then
    MPICC=gcc
    MPIFC=gfortran
    MPIFL=gfortran
else
    MPICC=mpicc
    MPIFC=mpifort
    MPIFL=mpifort
fi

LSCOTCH="-L${libdir} -lesmumps -lscotch"
FSCOTCH="-Dscotch"

### PTSCOTCH ###
# LSCOTCH="-lptesmumps -lptscotch -lptscotcherr"
# FSCOTCH="-Dptscotch"

make_args+=(PLAT="par" \
            OPTF="-O3 -fopenmp" \
            OPTL="-O3 -fopenmp" \
            OPTC="-O3 -fopenmp" \
            CDEFS=-DAdd_ \
            LMETISDIR="${libdir}" \
            IMETIS="-I${includedir}" \
            LMETIS="-L${libdir} -lparmetis -lmetis" \
            LSCOTCHDIR=${libdir} \
            ISCOTCH="-I${includedir}" \
            LSCOTCH="${LSCOTCH}" \
            ORDERINGSF="-Dmetis -Dpord -Dparmetis ${FSCOTCH}" \
            LIBEXT_SHARED=".${dlext}" \
            SHARED_OPT="-shared" \
            SONAME="${SONAME}" \
            CC="${MPICC} ${CFLAGS[@]}" \
            FC="${MPIFC} ${FFLAGS[@]}" \
            FL="${MPIFL}" \
            RANLIB="echo" \
            LPORD="-L./PORD/lib -lpordpar" \
            LAPACK="-L${libdir} -lopenblas" \
            SCALAP="-L${libdir} -lscalapack32" \
            INCPAR="-I${includedir}" \
            LIBPAR="-L${libdir} -lscalapack32 -lopenblas ${MPILIBS[*]}" \
            LIBBLAS="-L${libdir} -lopenblas")

make -j${nproc} allshared "${make_args[@]}"

cp include/*.h ${includedir}
cp lib/*.${dlext} ${libdir}
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)
platforms, platform_dependencies = MPI.augment_platforms(platforms; MPItrampoline_compat="5.2.1")

# Remove platforms where some dependencies are missing
filter!(p -> arch(p) != "riscv64", platforms)
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)

# OpenBLAS >= 0.3.29 doesn't support GCC < v11 on powerpc64le
filter!(p -> !(arch(p) == "powerpc64le" && libgfortran_version(p) < v"5"), platforms)

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && nbits(p) == 32), platforms)
platforms = filter(p -> !(p["mpi"] == "openmpi" && Sys.isfreebsd(p)), platforms)
platforms = filter(p -> !(p["mpi"] == "openmpi" && Sys.iswindows(p)), platforms)
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "x86_64" && os(p) == "linux" && libc(p) == "musl" && libgfortran_version(p) == v"5"), platforms)

# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libsmumpspar", :libsmumpspar),
    LibraryProduct("libdmumpspar", :libdmumpspar),
    LibraryProduct("libcmumpspar", :libcmumpspar),
    LibraryProduct("libzmumpspar", :libzmumpspar),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="METIS_jll", uuid="d00139f3-1899-568f-a2f0-47f597d42d70")),
    Dependency(PackageSpec(name="PARMETIS_jll", uuid="b247a4be-ddc1-5759-8008-7e02fe3dbdaa")),
    Dependency(PackageSpec(name="SCOTCH_jll", uuid="a8d0f55d-b80e-548d-aff6-1a04c175f0f9"); compat="~7.0.6"),
    # Dependency(PackageSpec(name="PTSCOTCH_jll", uuid="b3ec0f5a-9838-5c9b-9e77-5f2c6a4b089f"); compat="~7.0.6"),
    Dependency(PackageSpec(name="SCALAPACK32_jll", uuid="aabda75e-bfe4-5a37-92e3-ffe54af3c273"); compat="2.1.0 - 2.2.1"),
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2")),
]
append!(dependencies, platform_dependencies)

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"6")
