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
cd $WORKSPACE/srcdir/MUMPS_4.10.0

# Patch from Coin-OR ThirdPartyMUMPS
(cd src && atomic_patch -p2 $WORKSPACE/srcdir/patches/mumps.patch)
# Patch from JuliaOpt CoinMumpsBuilder
(cd src && atomic_patch -p3 $WORKSPACE/srcdir/patches/quiet.diff)

cp Make.inc/Makefile.gfortran.SEQ Makefile.inc

make_args+=(OPTF=-O3
            CDEFS=-DAdd_
            LMETISDIR=${prefix}/lib
            IMETIS=-I${prefix}/include
            LMETIS='-L$(LMETISDIR) -lmetis'
            ORDERINGSF="-Dpord -Dmetis"
            CC="$CC -fPIC ${CFLAGS[@]}"
            FC="gfortran -fPIC ${FFLAGS[@]}"
            FL="gfortran -fPIC"
            LIBBLAS="-L${prefix}/lib -lopenblas")

if [[ "${target}" == *-apple* ]]; then
  make_args+=(RANLIB=echo)
fi

# NB: parallel build fails
make alllib "${make_args[@]}"

mkdir -p ${prefix}/lib

cd libseq
mv libmpiseq.a ${prefix}/lib

cd ../lib
mv *.a ${prefix}/lib

cd ..
mkdir -p ${prefix}/include/mumps_seq
cp include/* ${prefix}/include/mumps_seq
cp libseq/*.h ${prefix}/include/mumps_seq
"""

platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = Product[
    FileProduct("lib/libsmumps.a", :libsmumps_a),
    FileProduct("lib/libdmumps.a", :libdmumps_a),
    FileProduct("lib/libcmumps.a", :libcmumps_a),
    FileProduct("lib/libzmumps.a", :libzmumps_a),
]

# Dependencies that must be installed before this package can be built
dependencies = [.
    BuildDependency(PackageSpec(; name = "METIS_jll",
                                uuid = "d00139f3-1899-568f-a2f0-47f597d42d70",
                                version = v"4.0.3")),
    BuildDependency("OpenBLAS32_jll"),
    BuildDependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"6")
