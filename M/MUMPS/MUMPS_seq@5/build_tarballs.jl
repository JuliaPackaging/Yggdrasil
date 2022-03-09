using BinaryBuilder

name = "MUMPS_seq"
version = v"5.4.1"

sources = [
  ArchiveSource("http://mumps.enseeiht.fr/MUMPS_$version.tar.gz",
                "93034a1a9fe0876307136dcde7e98e9086e199de76f1c47da822e7d4de987fa8"),
  DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${libdir}
cd $WORKSPACE/srcdir/MUMPS*
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mumps_int32.patch

makefile="Makefile.G95.SEQ"
cp Make.inc/${makefile} Makefile.inc

if [[ "${target}" == aarch64-apple-darwin* ]]; then
    # Fix the error:
    #     Type mismatch in argument ‘s’ at (1); passed INTEGER(4) to LOGICAL(4)
    FFLAGS=("-fallow-argument-mismatch")
fi

make_args+=(OPTF=-O3
            CDEFS=-DAdd_
            LMETISDIR=${libdir}
            IMETIS=-I${prefix}/include
            LMETIS='-L$(LMETISDIR) -lmetis'
            ORDERINGSF="-Dpord -Dmetis"
            CC="$CC -fPIC ${CFLAGS[@]}"
            FC="gfortran -fPIC ${FFLAGS[@]}"
            FL="gfortran -fPIC"
            LIBBLAS="-L${libdir} -lopenblas"
            LAPACK="-L${libdir} -lopenblas")

if [[ "${target}" == *-apple* ]]; then
  make_args+=(RANLIB=echo)
fi

# NB: parallel build fails
make all "${make_args[@]}"

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
libs=(-L${libdir} -lmetis -lopenblas -lmpiseq)
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

platforms = expand_gfortran_versions(supported_platforms(;experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct("libsmumps", :libsmumps),
    LibraryProduct("libdmumps", :libdmumps),
    LibraryProduct("libcmumps", :libcmumps),
    LibraryProduct("libzmumps", :libzmumps),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("METIS_jll"),
    Dependency("OpenBLAS32_jll"),
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat = "1.6", preferred_gcc_version=v"5")
