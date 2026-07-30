using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "MUMPS64"
version = v"5.9.0"
ygg_version = v"5.9.0"

sources = [
  ArchiveSource("https://mumps-solver.org/MUMPS_$(version).tar.gz",
                "02c6efdb91749ec0f82351d40f3f860547272a1eb1d899126a4265b4d6bcc4ca")
]

# ILP64 parallel MUMPS: -fdefault-integer-8 / -DINTSIZE64, BLAS/LAPACK via
# libblastrampoline `_64_`-suffixed symbols, links to libscalapack64.
script = raw"""
mkdir -p ${libdir}
cd $WORKSPACE/srcdir/MUMPS*

makefile="Makefile.G95.PAR"
cp Make.inc/${makefile} Makefile.inc

# Add `-fallow-argument-mismatch` if supported
: >empty.f
FFLAGS=()
if gfortran -c -fallow-argument-mismatch empty.f >/dev/null 2>&1; then
    FFLAGS+=("-fallow-argument-mismatch")
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

# Discover ScaLAPACK64 symbol base names (strip `_64_`) so we can rewrite
# MUMPS's unsuffixed calls to the `_64_` exports via cpp -D defines.
if [[ ${target} == *apple* ]]; then
    NM=llvm-nm
    NM_FILTER='$2 ~ /^[TW]$/ {sub(/^_/, "", $3); print $3}'
else
    NM=${target}-nm
    NM_FILTER='$2 ~ /^[TW]$/ {print $3}'
fi
${NM} --defined-only --extern-only ${libdir}/libscalapack64.${dlext} 2>/dev/null \
    | awk "${NM_FILTER}" \
    | grep -E '_64_$' \
    | sed 's/_64_$//' \
    | sort -u > /tmp/scalapack_syms.txt

# BLAS/LAPACK symbols MUMPS calls; routed via LBT's `_64_` suffix.
blas_lapack_syms=(
    isamax idamax icamax izamax ilaenv lsame xerbla
    slamch dlamch
    sasum dasum scasum dzasum
    snrm2 dnrm2 scnrm2 dznrm2
    saxpy daxpy caxpy zaxpy
    scopy dcopy ccopy zcopy
    sdot ddot
    sscal dscal cscal zscal csscal zdscal
    sswap dswap cswap zswap
    sgemm dgemm cgemm zgemm
    sgemv dgemv cgemv zgemv
    sger dger cgerc zgerc cgeru zgeru
    ssymv dsymv chemv zhemv
    ssyr dsyr cher zher
    ssyr2 dsyr2 cher2 zher2
    ssymm dsymm chemm zhemm csymm zsymm
    ssyrk dsyrk cherk zherk csyrk zsyrk
    ssyr2k dsyr2k cher2k zher2k csyr2k zsyr2k
    strmm dtrmm ctrmm ztrmm
    strsm dtrsm ctrsm ztrsm
    strmv dtrmv ctrmv ztrmv
    strsv dtrsv ctrsv ztrsv
    sgesv dgesv cgesv zgesv
    sgetrf dgetrf cgetrf zgetrf
    sgetrs dgetrs cgetrs zgetrs
    spotrf dpotrf cpotrf zpotrf
    sgesvd dgesvd cgesvd zgesvd
    slarfg dlarfg clarfg zlarfg
    sorgqr dorgqr cungqr zungqr
    sormqr dormqr cunmqr zunmqr
    strtrs dtrtrs ctrtrs ztrtrs
    slacpy dlacpy clacpy zlacpy
    slaset dlaset claset zlaset
    slaswp dlaswp claswp zlaswp
    slamch dlamch
    slange dlange clange zlange
    sgeqrf dgeqrf cgeqrf zgeqrf
    sgeqp3 dgeqp3 cgeqp3 zgeqp3
)

# cpp is case-sensitive but Fortran isn't, so emit both case variants for F.
: >/tmp/fortran_defines.txt
: >/tmp/c_defines.txt
{ cat /tmp/scalapack_syms.txt; printf '%s\n' "${blas_lapack_syms[@]}"; } | sort -u \
    | while read -r s; do
        [[ -z "$s" ]] && continue
        upper=$(echo "$s" | tr 'a-z' 'A-Z')
        echo "-D${s}=${s}_64"     >> /tmp/fortran_defines.txt
        echo "-D${upper}=${upper}_64" >> /tmp/fortran_defines.txt
        echo "-D${s}_=${s}_64_"   >> /tmp/c_defines.txt
    done
RENAME_F=$(tr '\n' ' ' < /tmp/fortran_defines.txt)
RENAME_C=$(tr '\n' ' ' < /tmp/c_defines.txt)

LSCOTCH=""
FSCOTCH=""

# MPI Fortran headers (mpif_jll, mpitrampoline, …) use `&` at col 73 paired
# with `&` at col 6 of the next line, relying on fixed-72 truncation.
# `-ffixed-line-length-none` defeats this. mpifort hardcodes `-I${includedir}`
# first, so we patch in place (originals are read-only artifact symlinks).
for f in "${includedir}"/*.h; do
    [[ -e "$f" ]] || continue
    if awk 'length($0)>=73 && substr($0,73,1)=="&" {found=1; exit} END {exit !found}' "$f"; then
        cp -L "$f" "${f}.tmp"
        rm -f "$f"
        mv "${f}.tmp" "$f"
        chmod u+w "$f"
        sed -i 's/&[[:space:]]*$//' "$f"
    fi
done

make_args+=(PLAT="par64"
            OPTF="-O3 -fopenmp -fdefault-integer-8 -ffixed-line-length-none -cpp ${RENAME_F}"
            OPTL="-O3 -fopenmp"
            OPTC="-O3 -fopenmp -DINTSIZE64 -DIDXTYPEWIDTH=64 -DREALTYPEWIDTH=64 ${RENAME_C}"
            CDEFS=-DAdd_
            LMETISDIR="${libdir}/metis/metis_Int64_Real64/lib"
            IMETIS="-I${libdir}/metis/metis_Int64_Real64/include"
            LMETIS="-L${libdir} -lparmetis_Int64_Real64 -L${libdir}/metis/metis_Int64_Real64/lib -lmetis_Int64_Real64"
            LSCOTCHDIR="${libdir}"
            ISCOTCH=""
            LSCOTCH=""
            ORDERINGSF="-Dmetis -Dpord -Dparmetis"
            LIBEXT_SHARED=".${dlext}"
            SHARED_OPT="-shared"
            SONAME="${SONAME}"
            CC="${MPICC} ${CFLAGS[@]}"
            FC="${MPIFC} ${FFLAGS[@]}"
            FL="${MPIFL}"
            RANLIB="echo"
            LPORD="-L./PORD/lib -lpordpar64"
            LIBBLAS="${BLAS_LAPACK}"
            LAPACK="${BLAS_LAPACK}"
            SCALAP="-L${libdir} -lscalapack64"
            INCPAR="-I${includedir}"
            LIBPAR="-L${libdir} -lscalapack64 ${BLAS_LAPACK} ${MPILIBS[*]}")

make -j${nproc} allshared "${make_args[@]}"

cp include/*.h ${includedir}
cp lib/*.${dlext} ${libdir}
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

platforms = expand_gfortran_versions(supported_platforms())
platforms = filter(p -> nbits(p) == 64, platforms)
# SCALAPACK64_jll has no Windows build, so MUMPS64 can't link there either.
platforms = filter(!Sys.iswindows, platforms)
platforms, platform_dependencies = MPI.augment_platforms(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libsmumpspar64", :libsmumpspar64),
    LibraryProduct("libdmumpspar64", :libdmumpspar64),
    LibraryProduct("libcmumpspar64", :libcmumpspar64),
    LibraryProduct("libzmumpspar64", :libzmumpspar64),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # libgomp on glibc/musl/freebsd, libomp from LLVM on Darwin (Apple clang ships no omp.h).
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               platforms=filter(!Sys.isapple, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms=filter(Sys.isapple, platforms)),
    Dependency(PackageSpec(name="METIS_jll", uuid="d00139f3-1899-568f-a2f0-47f597d42d70"); compat="5.1.3"),
    Dependency(PackageSpec(name="PARMETIS_jll", uuid="b247a4be-ddc1-5759-8008-7e02fe3dbdaa"); compat="4.0.7"),
    Dependency(PackageSpec(name="SCALAPACK64_jll", uuid="575e156b-18ce-583f-9f61-e5186a0cefa5"); compat="2.2.3"),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.4.0"),
    Dependency("mpif_jll"; compat="0.1.5", platforms=filter(p -> p["mpi"] == "mpiabi", platforms)),
]
append!(dependencies, platform_dependencies)

build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.10", preferred_gcc_version=v"9")
