using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "SCALAPACK"
version = v"2.2.2"

sources = [
  GitSource("https://github.com/Reference-ScaLAPACK/scalapack", "25935e1a7e022ede9fd71bd86dcbaa7a3f1846b7"),
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${libdir}
cd $WORKSPACE/srcdir/scalapack

CPPFLAGS=()
CFLAGS=(-Wno-error=implicit-function-declaration)
FFLAGS=(-cpp -ffixed-line-length-none)

# Add `-fallow-argument-mismatch` if supported
: >empty.f
if gfortran -c -fallow-argument-mismatch empty.f >/dev/null 2>&1; then
    FFLAGS+=(-fallow-argument-mismatch)
fi
rm -f empty.*

# Add `-fcray-pointer` if supported
: >empty.f
if gfortran -c -fcray-pointer empty.f >/dev/null 2>&1; then
    FFLAGS+=(-fcray-pointer)
fi
rm -f empty.*

if [[ "${target}" == *mingw* ]]; then
  LBT=(-lblastrampoline-5)
else
  LBT=(-lblastrampoline)
fi

if [[ ${nbits} == 64 ]]; then
    CPPFLAGS+=(-DInt=long)
    FFLAGS+=(-fdefault-integer-8)
    syms=(caxpy cbdsqr ccopy cdotc cdotu cgbmv cgbtrf cgemm cgemv cgerc cgeru cgesv cgetrf cgetrs chbmv chemm chemv cher cher2 cher2k cherk chetrd clacgv clacpy cladiv clanhs clarfg clartg claset clasr classq claswp cpbtrf cpotrf cpttrf crot csbmv cscal csscal cswap csymm csyr2k csyrk ctbtrs ctrmm ctrmv ctrsm ctrsv ctrtrs dasum daxpy dbdsqr dcopy ddot dgbmv dgbtrf dgemm dgemv dger dgesv dgetrf dgetrs dhbmv disnan dlabad dlacpy dladiv dlae2 dlaebz dlaed4 dlaev2 dlagtf dlagts dlahqr dlamc3 dlamch dlange dlanst dlanv2 dlapy2 dlapy3 dlaqr0 dlaqr1 dlaqr3 dlaqr4 dlarfg dlarfx dlarnv dlarra dlarrb dlarrc dlarrd dlarrk dlarrv dlartg dlaruv dlascl dlaset dlasq2 dlasr dlasrt dlassq dlaswp dlasy2 dnrm2 dpbtrf dpotrf dpttrf drot dsbmv dscal dstedc dsteqr dsterf dswap dsymm dsymv dsyr dsyr2 dsyr2k dsyrk dsytrd dtbtrs dtrmm dtrmv dtrsm dtrsv dtrtrs dzasum dznrm2 dzsum1 icamax icmax1 idamax ieeeck ilaenv isamax izamax izmax1 lsame lsamen sasum saxpy sbdsqr scasum scnrm2 scopy scsum1 sdot sgbmv sgbtrf sgemm sgemv sger sgesv sgetrf sgetrs shbmv sisnan slabad slacpy sladiv slae2 slaebz slaed4 slaev2 slagtf slagts slahqr slamc3 slamch slange slanst slanv2 slapy2 slapy3 slaqr0 slaqr1 slaqr3 slaqr4 slarfg slarfx slarnv slarra slarrb slarrc slarrd slarrk slarrv slartg slaruv slascl slaset slasq2 slasr slasrt slassq slaswp slasy2 snrm2 spbtrf spotrf spttrf srot ssbmv sscal sstedc ssteqr ssterf sswap ssymm ssymv ssyr ssyr2 ssyr2k ssyrk ssytrd stbtrs strmm strmv strsm strsv strtrs xerbla zaxpy zbdsqr zcopy zdbmv zdotc zdotu zdscal zgbmv zgbtrf zgemm zgemv zgerc zgeru zgesv zgetrf zgetrs zhbmv zhemm zhemv zher zher2 zher2k zherk zhetrd zlacgv zlacpy zladiv zlanhs zlarfg zlartg zlaset zlasr zlassq zlaswp zpbtrf zpotrf zpttrf zrot zscal zswap zsymm zsyr2k zsyrk ztbtrs ztrmm ztrmv ztrsm ztrsv ztrtrs)
    for sym in ${syms[@]}; do
        CPPFLAGS+=("-D${sym}=${sym}_64")
        CPPFLAGS+=("-D${sym}_=${sym}_64_")   # due to some evil #defines in SCALAPACK
        CPPFLAGS+=("-D${sym^^}=${sym}_64")
    done
fi

# We need to specify the MPI libraries explicitly because the
# CMakeLists.txt doesn't properly add them when linking
MPI_SETTINGS=(-DMPI_BASE_DIR="${prefix}")
MPILIBS=()
if [[ ${bb_full_target} == *microsoftmpi* ]]; then
    MPI_SETTINGS+=(-DMPI_GUESS_LIBRARY_NAME=MSMPI)
    MPILIBS=(-lmsmpifec64 -lmsmpi64)
elif [[ ${bb_full_target} == *mpich* ]]; then
    MPILIBS=(-lmpifort -lmpi)
elif [[ ${bb_full_target} == *mpitrampoline* ]]; then
    MPILIBS=(-lmpitrampoline)
elif [[ ${bb_full_target} == *openmpi* ]]; then
    MPILIBS=(-lmpi_usempif08 -lmpi_usempi_ignore_tkr -lmpi_mpifh -lmpi)
fi

CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=${prefix}
             -DCMAKE_FIND_ROOT_PATH=${prefix}
             -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}"
             -DCMAKE_Fortran_FLAGS="${CPPFLAGS[*]} ${FFLAGS[*]}"
             -DCMAKE_C_FLAGS="${CPPFLAGS[*]} ${CFLAGS[*]}"
             -DCMAKE_BUILD_TYPE=Release
             -DBLAS_LIBRARIES="${LBT[*]} ${MPILIBS[*]}"
             -DLAPACK_LIBRARIES="${LBT[*]}"
             -DSCALAPACK_BUILD_TESTS=OFF
             -DBUILD_SHARED_LIBS=ON
             ${MPI_SETTINGS[*]}
             -DCDEFS=Add_)

mkdir build
cd build
cmake .. "${CMAKE_FLAGS[@]}"

make -j${nproc} all
make install
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

platforms = expand_gfortran_versions(supported_platforms())
# Don't know how to configure MPI for Windows
platforms = filter(p -> !Sys.iswindows(p), platforms)

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# Internal compiler error for v2.2.2 for:
filter!(p -> !(arch(p) == "aarch64" && Sys.islinux(p) && libgfortran_version(p) == v"4" && p["mpi"] == "mpich"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libscalapack", :libscalapack),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.4.0"),
]
append!(dependencies, platform_dependencies)

# Build the tarballs.
# We need at least GCC 5 for MPICH
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.9", preferred_gcc_version=v"5")
