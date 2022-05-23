using BinaryBuilder, Pkg

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

if [[ "${target}" == aarch64-apple-darwin* ]]; then
    # Fix the error:
    #     Type mismatch in argument ‘s’ at (1); passed INTEGER(4) to LOGICAL(4)
    FFLAGS=("-fallow-argument-mismatch")
fi

if [[ "${target}" == *-apple* ]]; then
  CFLAGS=("-fno-stack-check")
fi

make_args+=(OPTF=-O \
            CDEFS=-DAdd_ \
            LMETISDIR=${prefix} \
            IMETIS="-I${includedir}" \
            LMETIS="-L${libdir} -lparmetis -lmetis" \
            ORDERINGSF="-Dpord -Dparmetis" \
            CC="mpicc -fPIC ${CFLAGS[@]}" \
            FC="mpif90 -fPIC ${FFLAGS[@]}" \
            FL="mpif90 -fPIC" \
            SCALAP="${libdir}/scalapack32.${dlext} ${libdir}/libopenblas.${dlext}" \
            INCPAR= \
            LIBPAR=-lscalapack32 \
            LIBBLAS=-lopenblas)

# Options for SCOTCH
# LSCOTCHDIR=${prefix}
# ISCOTCH="-I${includedir}"
# LSCOTCH="-L${libdir} -lesmumps -lscotch -lscotcherr"
# ORDERINGSF="-Dpord -Dparmetis -Dscotch"

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
libs=(-lparmetis -lmetis -lscalapack32 -lopenblas)
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
# MUMPS doesn't build on PowerPC
platforms = expand_gfortran_versions(filter!(p -> !Sys.iswindows(p) && arch(p) != "powerpc64le", supported_platforms()))

# The products that we will ensure are always built
products = [
    LibraryProduct("libsmumps", :libsmumps),
    LibraryProduct("libdmumps", :libdmumps),
    LibraryProduct("libcmumps", :libcmumps),
    LibraryProduct("libzmumps", :libzmumps)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="MPICH_jll", uuid="7cb0a576-ebde-5e09-9194-50597f1243b4")),
    Dependency(PackageSpec(name="METIS_jll", uuid="d00139f3-1899-568f-a2f0-47f597d42d70")),
    Dependency(PackageSpec(name="SCOTCH_jll", uuid="a8d0f55d-b80e-548d-aff6-1a04c175f0f9")),
    Dependency(PackageSpec(name="PARMETIS_jll", uuid="b247a4be-ddc1-5759-8008-7e02fe3dbdaa")),
    Dependency(PackageSpec(name="SCALAPACK32_jll", uuid="aabda75e-bfe4-5a37-92e3-ffe54af3c273")),
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2")),
    # Dependency(PackageSpec(name="SCOTCH_jll", uuid="a8d0f55d-b80e-548d-aff6-1a04c175f0f9"))
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
