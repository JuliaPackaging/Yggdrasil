using BinaryBuilder

name = "MUMPS"
version = v"5.4.2" # <-- This is a lie, we're bumping to 5.4.2 to create a Julia v1.6+ release with experimental platforms

sources = [
  ArchiveSource("http://mumps.enseeiht.fr/MUMPS_5.4.1.tar.gz",
                "93034a1a9fe0876307136dcde7e98e9086e199de76f1c47da822e7d4de987fa8"),
  DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${libdir}
cd $WORKSPACE/srcdir/MUMPS*
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mumps_int32.patch

makefile="Makefile.G95.PAR"
cp Make.inc/${makefile} Makefile.inc

make_args+=(OPTF="-O -DGEMMT_AVAILABLE" \
            CDEFS=-DAdd_ \
            LMETISDIR=${prefix} \
            IMETIS="-I${includedir}" \
            LMETIS="-L${libdir} -lparmetis -lmetis" \
            LSCOTCHDIR=${prefix} \
            ISCOTCH="-I${includedir}" \
            LSCOTCH="-L${libdir} -lesmumps -lscotch -lscotcherr" \
            ORDERINGSF="-Dpord -Dparmetis -Dscotch" \
            CC="mpicc -fPIC" \
            FC="mpif90 -fPIC" \
            FL="mpif90 -fPIC" \
            SCALAP="${libdir}/scalapack32.${dlext} ${libdir}/libopenblas.${dlext}" \
            INCPAR= \
            LIBPAR=-lmpich \
            LIBBLAS=-lopenblas)

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

cd lib
libs=(-lesmumps -lscotch -lscotcherr -lparmetis -lmetis -lscalapack32 -lopenblas)
mpif90 -fPIC -shared -Wl,${all_load} libpord.a ${libs[@]} -Wl,${noall_load} ${extra[@]} -o libpord.${dlext}
cp libpord.${dlext} ${libdir}

libs+=(-L${libdir} -lpord)
mpif90 -fPIC -shared -Wl,${all_load} libmumps_common.a ${libs[@]} -Wl,${noall_load} ${extra[@]} -o libmumps_common.${dlext}
cp libmumps_common.${dlext} ${libdir}

libs+=(-lmumps_common)
for libname in cmumps dmumps smumps zmumps
do
  mpif90 -fPIC -shared -Wl,${all_load} lib${libname}.a ${libs[@]} -Wl,${noall_load} ${extra[@]} -o lib${libname}.${dlext}
done
cp *.${dlext} ${libdir}
cd ..

cp include/* ${prefix}/include
"""

# OpenMPI and MPICH are not precompiled for Windows
# SCALAPACK doesn't build on PowerPC
platforms = expand_gfortran_versions(filter!(p -> !Sys.iswindows(p) && arch(p) != "powerpc64le", supported_platforms()))

# The products that we will ensure are always built
products = [
    LibraryProduct("libsmumps", :libsmumps),
    LibraryProduct("libdmumps", :libdmumps),
    LibraryProduct("libcmumps", :libcmumps),
    LibraryProduct("libzmumps", :libzmumps),
    LibraryProduct("libmumps_common", :libmumps_common)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("MPICH_jll"),
    Dependency("METIS_jll"),
    Dependency("SCOTCH_jll"),
    Dependency("PARMETIS_jll"),
    Dependency("SCALAPACK32_jll"),
    Dependency("OpenBLAS32_jll"),
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
