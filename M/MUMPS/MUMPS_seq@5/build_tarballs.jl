using BinaryBuilder, Pkg

# The version of this JLL is decoupled from the upstream version.
# Whenever we package a new upstream release, we initially map its
# version X.Y.Z to X00.Y00.Z00 (i.e., multiply each component by 100).
# So for example version 2.6.3 would become 200.600.300.
#
# Together, this allows to increment the patch level of the JLL for minor tweaks.
# If a rebuild of the JLL is needed which keeps the upstream version identical
# but breaks ABI compatibility for any reason, one can increment the minor or major
# version (depending on whether package using this JLL use `~` or `^` compat entries)
# e.g. go from 200.600.300 to 200.601.300 or 201.600.300
# Similar tricks can also be used to package prerelease versions; e.g. one might
# map a prerelease of 2.7.0 to 200.690.000.

name = "MUMPS_seq"
upstream_version = v"5.7.3"
version_offset = v"0.0.1" # reset to 0.0.0 once the upstream version changes
version = VersionNumber(upstream_version.major * 100 + version_offset.major,
                        upstream_version.minor * 100 + version_offset.minor,
                        upstream_version.patch * 100 + version_offset.patch)

sources = [
  ArchiveSource("https://mumps-solver.org/MUMPS_$(upstream_version).tar.gz",
                "84a47f7c4231b9efdf4d4f631a2cae2bdd9adeaabc088261d15af040143ed112")
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${libdir}
cd $WORKSPACE/srcdir/MUMPS*

makefile="Makefile.G95.SEQ"
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

make_args+=(OPTF="-O3"
            OPTL="-O3"
            OPTC="-O3"
            CDEFS=-DAdd_
            LMETISDIR=${libdir}
            IMETIS=-I${includedir}
            LMETIS="-L${libdir} -lmetis"
            ORDERINGSF="-Dpord -Dmetis"
            LIBEXT_SHARED=".${dlext}"
            SHARED_OPT="-shared"
            SONAME="${SONAME}"
            CC="$CC ${CFLAGS[@]}"
            FC="gfortran ${FFLAGS[@]}"
            FL="gfortran"
            RANLIB="echo"
            LIBBLAS="${BLAS_LAPACK}"
            LAPACK="${BLAS_LAPACK}")

make -j${nproc} allshared "${make_args[@]}"

mkdir ${includedir}/libseq
cp include/*.h ${includedir}
cp libseq/*.h ${includedir}/libseq
cp lib/*.${dlext} ${libdir}

# 64-bit integer version of MUMPS
make clean
for sym in isamax idamax ilaenv slamch dlamch \
           saxpy scopy sgemm sgemv sgesvd slarfg sorgqr sormqr sscal sswap strsv strsm strtrs snrm2 \
           daxpy dcopy dgemm dgemv dgesvd dlarfg dorgqr dormqr dscal dswap dtrsv dtrsm dtrtrs dnrm2 \
           caxpy ccopy cgemm cgemv cgesvd clarfg cungqr cunmqr cscal cswap ctrsv ctrsm ctrtrs scnrm2 \
           zaxpy zcopy zgemm zgemv zgesvd zlarfg zungqr zunmqr zscal zswap ztrsv ztrsm ztrtrs dznrm2
do
    FFLAGS+=("-D${sym}=${sym}_64")
done
FFLAG="${FFLAGS[@]}"
make_args_64+=(PLAT="64"
               OPTF="-O3 -fdefault-integer-8 -ffixed-line-length-none"
               OPTL="-O3"
               OPTC="-O3 -DINTSIZE64"
               CDEFS=-DAdd_
               LMETISDIR="${libdir}/metis/metis_Int64_Real32/lib"
               IMETIS="-I${libdir}/metis_Int64_Real32/include"
               LMETIS="-L${libdir}/metis/metis_Int64_Real32/lib -lmetis_Int64_Real32"
               ORDERINGSF="-Dpord -Dmetis"
               LIBEXT_SHARED=".${dlext}"
               SHARED_OPT="-shared"
               SONAME="${SONAME}"
               CC="$CC ${CFLAGS[@]}"
               FC="gfortran $FFLAG"
               FL="gfortran"
               RANLIB="echo"
               LPORD="-L./PORD/lib -lpord64"
               LIBBLAS="${BLAS_LAPACK}"
               LAPACK="${BLAS_LAPACK}")

make -j${nproc} allshared "${make_args_64[@]}"
cp lib/*.${dlext} ${libdir}
"""

platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libsmumps", :libsmumps),
    LibraryProduct("libdmumps", :libdmumps),
    LibraryProduct("libcmumps", :libcmumps),
    LibraryProduct("libzmumps", :libzmumps),
    LibraryProduct("libsmumps64", :libsmumps64),
    LibraryProduct("libdmumps64", :libdmumps64),
    LibraryProduct("libcmumps64", :libcmumps64),
    LibraryProduct("libzmumps64", :libzmumps64),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="METIS_jll", uuid="d00139f3-1899-568f-a2f0-47f597d42d70")),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.4.0"),
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat = "1.9", preferred_gcc_version=v"6", clang_use_lld=false)
