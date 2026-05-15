using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "SCALAPACK64"
version = v"2.2.3"
ygg_version = v"2.2.3"

sources = [
  GitSource("https://github.com/Reference-ScaLAPACK/scalapack", "3e0da655fb07de5f1d76d6afb43f16ae17ca98c4"),  # v2.2.3
]

script = raw"""
mkdir -p ${libdir}
cd $WORKSPACE/srcdir/scalapack

CFLAGS=(-Wno-error=implicit-function-declaration)
FFLAGS=(-cpp -ffixed-line-length-none)

: >empty.f
if gfortran -c -fallow-argument-mismatch empty.f >/dev/null 2>&1; then
    FFLAGS+=(-fallow-argument-mismatch)
fi
rm -f empty.*

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

# ILP64: 64-bit Fortran INTEGERs and 64-bit C `Int`.  Symbol naming is
# fixed up post-link with objcopy below.
CPPFLAGS=(-DInt=long)
FFLAGS+=(-fdefault-integer-8)

# BLAS/LAPACK names that ScaLAPACK calls into.  Used as the safety
# boundary for the post-link rewrite: only these undefined refs get
# redirected to libblastrampoline's `_64_` slot.  MPI/libc undefined
# refs are not in the list and stay untouched.
blas_lapack_syms=(caxpy cbdsqr ccopy cdotc cdotu cgbmv cgbtrf cgemm cgemv cgerc cgeru cgesv cgetrf cgetrs chbmv chemm chemv cher cher2 cher2k cherk chetrd clacgv clacpy cladiv clanhs clarfg clartg claset clasr classq claswp cpbtrf cpotrf cpttrf crot csbmv cscal csscal cswap csymm csyr2k csyrk ctbtrs ctrmm ctrmv ctrsm ctrsv ctrtrs dasum daxpy dbdsqr dcopy ddot dgbmv dgbtrf dgemm dgemv dger dgesv dgetrf dgetrs dhbmv disnan dlabad dlacpy dladiv dlae2 dlaebz dlaed4 dlaev2 dlagtf dlagts dlahqr dlamc3 dlamch dlange dlanst dlanv2 dlapy2 dlapy3 dlaqr0 dlaqr1 dlaqr3 dlaqr4 dlarfg dlarfx dlarnv dlarra dlarrb dlarrc dlarrd dlarrk dlarrv dlartg dlaruv dlascl dlaset dlasq2 dlasr dlasrt dlassq dlaswp dlasy2 dnrm2 dpbtrf dpotrf dpttrf drot dsbmv dscal dstedc dsteqr dsterf dswap dsymm dsymv dsyr dsyr2 dsyr2k dsyrk dsytrd dtbtrs dtrmm dtrmv dtrsm dtrsv dtrtrs dzasum dznrm2 dzsum1 icamax icmax1 idamax ieeeck ilaenv isamax izamax izmax1 lsame lsamen sasum saxpy sbdsqr scasum scnrm2 scopy scsum1 sdot sgbmv sgbtrf sgemm sgemv sger sgesv sgetrf sgetrs shbmv sisnan slabad slacpy sladiv slae2 slaebz slaed4 slaev2 slagtf slagts slahqr slamc3 slamch slange slanst slanv2 slapy2 slapy3 slaqr0 slaqr1 slaqr3 slaqr4 slarfg slarfx slarnv slarra slarrb slarrc slarrd slarrk slarrv slartg slaruv slascl slaset slasq2 slasr slasrt slassq slaswp slasy2 snrm2 spbtrf spotrf spttrf srot ssbmv sscal sstedc ssteqr ssterf sswap ssymm ssymv ssyr ssyr2 ssyr2k ssyrk ssytrd stbtrs strmm strmv strsm strsv strtrs xerbla zaxpy zbdsqr zcopy zdbmv zdotc zdotu zdscal zgbmv zgbtrf zgemm zgemv zgerc zgeru zgesv zgetrf zgetrs zhbmv zhemm zhemv zher zher2 zher2k zherk zhetrd zlacgv zlacpy zladiv zlanhs zlarfg zlartg zlaset zlasr zlassq zlaswp zpbtrf zpotrf zpttrf zrot zscal zswap zsymm zsyr2k zsyrk ztbtrs ztrmm ztrmv ztrsm ztrsv ztrtrs)

# CMakeLists.txt doesn't add MPI libs to the link line; pass them explicitly.
MPI_SETTINGS=(-DMPI_BASE_DIR="${prefix}")
MPILIBS=()
if [[ ${bb_full_target} == *microsoftmpi* ]]; then
    MPI_SETTINGS+=(-DMPI_GUESS_LIBRARY_NAME=MSMPI)
    MPILIBS=(-lmsmpifec64 -lmsmpi64)
elif [[ ${bb_full_target} == *mpiabi* ]]; then
    MPILIBS=(-lmpif -lmpi_abi)
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

# Rewrite symbols to the `_64_` convention used by libblastrampoline-aware
# callers (PETSc, MUMPS, ...).  Single objcopy pass over a rename map
# built from two sources:
#   1. ScaLAPACK's own defined exports (pdgemm_, numroc_, ...) — every
#      defined T/W text symbol ending in `_` and not already `_64_`,
#      enumerated dynamically so future upstream additions are covered.
#   2. BLAS/LAPACK undefined refs — drawn from blas_lapack_syms only,
#      not a blanket sweep, so MPI/libc undefined refs aren't renamed.
{
    nm -D --defined-only "${libdir}/libscalapack.${dlext}" \
        | awk '$2 ~ /^[TW]$/ {print $3}' \
        | grep -E '^[a-z][a-zA-Z0-9_]*_$' \
        | grep -v '_64_$' \
        | awk '{print $1, substr($1, 1, length($1)-1) "_64_"}'
    for sym in "${blas_lapack_syms[@]}"; do
        echo "${sym}_ ${sym}_64_"
    done
} > /tmp/scalapack_redefine.txt

${target}-objcopy --redefine-syms=/tmp/scalapack_redefine.txt \
    "${libdir}/libscalapack.${dlext}"

# Ship as libscalapack64 so it coexists with SCALAPACK_jll's libscalapack.
mv -v ${libdir}/libscalapack.${dlext} ${libdir}/libscalapack64.${dlext}

for l in $(find ${prefix}/lib -xtype l); do
  if [[ $(basename $(readlink ${l})) == libscalapack ]]; then
    ln -vsf libscalapack64.${dlext} ${l}
  fi
done

PATCHELF_FLAGS=()
# aarch64 / ppc64le have 64 kB page sizes
if [[ ${target} == aarch64-* || ${target} == powerpc64le-* ]]; then
  PATCHELF_FLAGS+=(--page-size 65536)
fi

if [[ ${target} == *linux* ]] || [[ ${target} == *freebsd* ]]; then
  patchelf ${PATCHELF_FLAGS[@]} --set-soname libscalapack64.${dlext} ${libdir}/libscalapack64.${dlext}
elif [[ ${target} == *apple* ]]; then
  install_name_tool -id libscalapack64.${dlext} ${libdir}/libscalapack64.${dlext}
fi
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

platforms = expand_gfortran_versions(supported_platforms())
platforms = filter(p -> !Sys.iswindows(p), platforms)  # MPI on Windows not configured
platforms = filter(p -> nbits(p) == 64, platforms)     # ILP64 needs 64-bit address space

platforms, platform_dependencies = MPI.augment_platforms(platforms)

products = [
    LibraryProduct("libscalapack64", :libscalapack64),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.4.0"),
    Dependency("mpif_jll"; compat="0.1.5", platforms=filter(p -> p["mpi"] == "mpiabi", platforms)),
]
append!(dependencies, platform_dependencies)

build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.9", preferred_gcc_version=v"5")
