using BinaryBuilder, Pkg

name = "MUMPS"
version = v"5.5.1"

sources = [
  ArchiveSource("https://graal.ens-lyon.fr/MUMPS/MUMPS_$(version).tar.gz",
                "1abff294fa47ee4cfd50dfd5c595942b72ebfcedce08142a75a99ab35014fa15"),
  DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${libdir}
cd $WORKSPACE/srcdir/MUMPS*
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/pord.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/Makefile.patch

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

if [[ "${target}" == *apple* ]]; then
    SONAME="-install_name"
else
    SONAME="-soname"
fi

make_args+=(OPTF=-O \
            CDEFS=-DAdd_ \
            LMETISDIR=${prefix} \
            IMETIS="-I${includedir}" \
            LMETIS="-L${libdir} -lparmetis -lmetis" \
            ORDERINGSF="-Dpord -Dparmetis" \
            LIBEXT_SHARED=".${dlext}" \
            SONAME="${SONAME}" \
            CC="mpicc -fPIC ${CFLAGS[@]}" \
            FC="mpif90 -fPIC ${FFLAGS[@]}" \
            FL="mpif90 -fPIC" \
            RANLIB="echo" \
            SCALAP="${libdir}/scalapack32.${dlext} ${libdir}/libopenblas.${dlext}" \
            INCPAR= \
            LIBPAR=-lscalapack32 \
            LIBBLAS=-lopenblas)

# Options for SCOTCH
# LSCOTCHDIR=${prefix}
# ISCOTCH="-I${includedir}"
# LSCOTCH="-L${libdir} -lesmumps -lscotch -lscotcherr"
# ORDERINGSF="-Dpord -Dparmetis -Dscotch"

make -j${nproc} allshared "${make_args[@]}"

cp include/*.h ${includedir}
cp lib/*.${dlext} ${libdir}
"""

# OpenMPI and MPICH are not precompiled for Windows
# MUMPS doesn't build on PowerPC
platforms = expand_gfortran_versions(filter!(p -> !Sys.iswindows(p), supported_platforms()))

# The products that we will ensure are always built
products = [
    LibraryProduct("libsmumps", :libsmumps),
    LibraryProduct("libdmumps", :libdmumps),
    LibraryProduct("libcmumps", :libcmumps),
    LibraryProduct("libzmumps", :libzmumps),
    LibraryProduct("libmumps_common", :libmumps_common),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="MPICH_jll", uuid="7cb0a576-ebde-5e09-9194-50597f1243b4")),
    Dependency(PackageSpec(name="METIS_jll", uuid="d00139f3-1899-568f-a2f0-47f597d42d70")),
    Dependency(PackageSpec(name="SCOTCH_jll", uuid="a8d0f55d-b80e-548d-aff6-1a04c175f0f9")),
    Dependency(PackageSpec(name="PARMETIS_jll", uuid="b247a4be-ddc1-5759-8008-7e02fe3dbdaa")),
    Dependency(PackageSpec(name="SCALAPACK32_jll", uuid="aabda75e-bfe4-5a37-92e3-ffe54af3c273")),
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6", preferred_gcc_version=v"6")
