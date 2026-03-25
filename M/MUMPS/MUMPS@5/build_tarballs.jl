using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "MUMPS"
version = v"5.8.2" 
ygg_version = v"5.8.3"          # we updated compat bounds to build for MPIABI

sources = [
  ArchiveSource("https://mumps-solver.org/MUMPS_$(version).tar.gz",
                "eb515aa688e6dbab414bb6e889ff4c8b23f1691a843c68da5230a33ac4db7039")
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

if [[ "${target}" == *mingw* ]]; then
  BLAS_LAPACK="-L${libdir} -lblastrampoline-5"
else
  BLAS_LAPACK="-L${libdir} -lblastrampoline"
fi

MPILIBS=()
if [[ ${bb_full_target} == *microsoftmpi* ]]; then
    MPILIBS=(-lmsmpi)
elif [[ ${bb_full_target} == *mpiabi* ]]; then
    MPILIBS=(-lmpif -lmpi_abi)
elif [[ ${bb_full_target} == *mpich* ]]; then
    MPILIBS=(-lmpifort -lmpi)
elif [[ ${bb_full_target} == *mpitrampoline* ]]; then
    MPILIBS=(-lmpitrampoline)
elif [[ ${bb_full_target} == *openmpi* ]]; then
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
            LIBBLAS="${BLAS_LAPACK}" \
            LAPACK="${BLAS_LAPACK}" \
            SCALAP="-L${libdir} -lscalapack32" \
            INCPAR="-I${includedir}" \
            LIBPAR="-L${libdir} -lscalapack32 ${BLAS_LAPACK} ${MPILIBS[*]}")

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
platforms, platform_dependencies = MPI.augment_platforms(platforms)

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
    Dependency(PackageSpec(name="METIS_jll", uuid="d00139f3-1899-568f-a2f0-47f597d42d70"); compat="5.1.3"),
    Dependency(PackageSpec(name="PARMETIS_jll", uuid="b247a4be-ddc1-5759-8008-7e02fe3dbdaa"); compat="4.0.7"),
    Dependency(PackageSpec(name="SCOTCH_jll", uuid="a8d0f55d-b80e-548d-aff6-1a04c175f0f9"); compat="~7.0.7"),
    # Dependency(PackageSpec(name="PTSCOTCH_jll", uuid="b3ec0f5a-9838-5c9b-9e77-5f2c6a4b089f"); compat="~7.0.6"),
    Dependency(PackageSpec(name="SCALAPACK32_jll", uuid="aabda75e-bfe4-5a37-92e3-ffe54af3c273"); compat="2.2.3"),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.4.0"),
    Dependency("mpif_jll"; compat="0.1.5", platforms=filter(p -> p["mpi"] == "mpiabi", platforms)), # MPI Fortran bindings
]
append!(dependencies, platform_dependencies)

# Build the tarballs
# We require Julia 1.9 since SCALAPACK32 only supports Julia 1.9
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.9", preferred_gcc_version=v"6")
