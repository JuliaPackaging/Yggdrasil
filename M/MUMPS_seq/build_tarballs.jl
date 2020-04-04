using BinaryBuilder

name = "MUMPS_seq"
version = v"5.2.1"

sources = [
  ArchiveSource("http://mumps.enseeiht.fr/MUMPS_5.2.1.tar.gz",
                "d988fc34dfc8f5eee0533e361052a972aa69cc39ab193e7f987178d24981744a"),
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${libdir}
cd $WORKSPACE/srcdir/MUMPS_5.2.1

OPENBLAS=(-lopenblas)
FFLAGS=()
CFLAGS=()
if [[ ${nbits} == 64 ]] && [[ ${target} != aarch64* ]]; then
  FFLAGS+=(-ffixed-line-length-none)  # replacing symbols below sometimes makes lines > 72 chars
  OPENBLAS=(-lopenblas64_)
  if [[ "${target}" == powerpc64le-linux-gnu ]]; then
    OPENBLAS+=(-lgomp)
  fi

  syms=(DGEMM IDAMAX ISAMAX SNRM2 XERBLA ccopy cgemm cgemv cgeru cher clarfg cscal cswap ctrsm ctrsv cungqr cunmqr dcopy dgemm dgemv dger dlamch dlarfg dorgqr dormqr dnrm2 dscal dswap dtrsm dtrsv dznrm2 idamax isamax ilaenv scnrm2 scopy sgemm sgemv sger slamch slarfg sorgqr sormqr snrm2 sscal sswap strsm strsv xerbla zcopy zgemm zgemv zgeru zlarfg zscal zswap ztrsm ztrsv zungqr zunmqr)
  for sym in ${syms[@]}
  do
    FFLAGS+=("-D${sym}=${sym}_64")
    CFLAGS+=("-D${sym}=${sym}_64")
  done
fi

makefile="Makefile.G95.SEQ"
cp Make.inc/${makefile} Makefile.inc

make_args+=(OPTF=-O
            CDEFS=-DAdd_
            LMETISDIR=${libdir}
            IMETIS=-I${prefix}/include
            LMETIS='-L$(LMETISDIR) -lmetis'
            ORDERINGSF="-Dpord -Dmetis"
            CC="$CC -fPIC ${CFLAGS[@]}"
            FC="gfortran -fPIC ${FFLAGS[@]}"
            FL="gfortran -fPIC"
            LIBBLAS=${OPENBLAS})

if [[ "${target}" == *-apple* ]]; then
  make_args+=(RANLIB=echo)
fi

# NB: parallel build fails
make alllib "${make_args[@]}"

# build shared libs
all_load="--whole-archive"
noall_load="--no-whole-archive"
extra=""
if [[ "${target}" == *-apple-* ]]; then
    all_load="-all_load"
    noall_load="-noall_load"
    extra="-Wl,-undefined -Wl,dynamic_lookup -headerpad_max_install_names"
fi

cd libseq
gfortran -fPIC -shared -Wl,${all_load} libmpiseq.a ${libs[@]} -Wl,${noall_load} ${extra[@]} -o libmpiseq.${dlext}
cp libmpiseq.${dlext} ${libdir}

cd ../lib
libs=(-L${libdir} -lmetis ${OPENBLAS} -lmpiseq)
gfortran -fPIC -shared -Wl,${all_load} libpord.a ${libs[@]} -Wl,${noall_load} ${extra[@]} -o libpord.${dlext}
cp libpord.${dlext} ${libdir}

libs+=(-lpord)
gfortran -fPIC -shared -Wl,${all_load} libmumps_common.a ${libs[@]} -Wl,${noall_load} ${extra[@]} -o libmumps_common.${dlext}
cp libmumps_common.${dlext} ${libdir}

libs+=(-lmumps_common)
for libname in cmumps dmumps smumps zmumps
do
  gfortran -fPIC -shared -Wl,${all_load} lib${libname}.a ${libs[@]} -Wl,${noall_load} ${extra[@]} -o lib${libname}.${dlext}
done
cp *.${dlext} ${libdir}
cd ..

mkdir -p ${prefix}/include/mumps_seq
cp include/* ${prefix}/include/mumps_seq
cp libseq/*.h ${prefix}/include/mumps_seq
"""

platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libsmumps", :libsmumps),
    LibraryProduct("libdmumps", :libdmumps),
    LibraryProduct("libcmumps", :libcmumps),
    LibraryProduct("libzmumps", :libzmumps),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("METIS_jll"),
    Dependency("OpenBLAS_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
