using BinaryBuilder, Pkg

name = "MUMPS_seq"
version = v"4.10.0"

sources = [
  ArchiveSource("http://mumps.enseeiht.fr/MUMPS_4.10.0.tar.gz",
                "d0f86f91a74c51a17a2ff1be9c9cee2338976f13a6d00896ba5b43a5ca05d933"),
  DirectorySource("bundled")
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${libdir}
cd $WORKSPACE/srcdir/MUMPS_4.10.0

#(cd src && atomic_patch -p0 $WORKSPACE/srcdir/patches/mumps.patch)
cp Make.inc/Makefile.gfortran.SEQ Makefile.inc

make_args+=(OPTF=-O3
            CDEFS=-DAdd_
            LMETISDIR=${libdir}
            IMETIS=-I${prefix}/include
            LMETIS='-L$(LMETISDIR) -lmetis'
            ORDERINGSF="-Dpord -Dmetis"
            CC="$CC -fPIC ${CFLAGS[@]}"
            FC="gfortran -fPIC ${FFLAGS[@]}"
            FL="gfortran -fPIC"
            LIBBLAS="-L${libdir} -lopenblas")

if [[ "${target}" == *-apple* ]]; then
  make_args+=(RANLIB=echo)
fi

# NB: parallel build fails
make alllib "${make_args[@]}"

cd libseq
cp libmpiseq.a ${libdir}

cd ../lib
cp *.a ${libdir}

cd ..
mkdir -p ${prefix}/include/mumps_seq
cp include/* ${prefix}/include/mumps_seq
cp libseq/*.h ${prefix}/include/mumps_seq
"""

platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = []

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency(PackageSpec(; name = "METIS_jll", uuid = "d00139f3-1899-568f-a2f0-47f597d42d70", version = v"4.0.3")),
    Dependency("OpenBLAS32_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
