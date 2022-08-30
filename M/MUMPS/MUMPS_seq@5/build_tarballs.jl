using BinaryBuilder

name = "MUMPS_seq"
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

makefile="Makefile.G95.SEQ"
cp Make.inc/${makefile} Makefile.inc

# Add `-fallow-argument-mismatch` if supported
: >empty.f
if gfortran -c -fallow-argument-mismatch empty.f >/dev/null 2>&1; then
    FFLAGS=("-fallow-argument-mismatch")
fi
rm -f empty.*

if [[ "${target}" == *apple* ]]; then
    SONAME="-install_name"
else
    SONAME="-soname"
fi

make_args+=(OPTF=-O3
            CDEFS=-DAdd_
            LMETISDIR=${libdir}
            IMETIS=-I${includedir}
            LMETIS='-L${libdir} -lmetis'
            ORDERINGSF="-Dpord -Dmetis"
            LIBEXT_SHARED=".${dlext}"
            SONAME="${SONAME}"
            CC="$CC -fPIC ${CFLAGS[@]}"
            FC="gfortran -fPIC ${FFLAGS[@]}"
            FL="gfortran -fPIC"
            RANLIB="echo"
            LIBBLAS="-L${libdir} -lblastrampoline"
            LAPACK="-L${libdir} -lblastrampoline")

make -j${nproc} allshared "${make_args[@]}"

cp include/*.h ${includedir}
cp libseq/*.h ${includedir}
cp lib/*.${dlext} ${libdir}
"""

platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libsmumps", :libsmumps),
    LibraryProduct("libdmumps", :libdmumps),
    LibraryProduct("libcmumps", :libcmumps),
    LibraryProduct("libzmumps", :libzmumps),
    LibraryProduct("libpord", :libpord),
    LibraryProduct("libmpiseq", :libmpiseq),
    LibraryProduct("libmumps_common", :libmumps_common),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("METIS_jll"),
    Dependency("libblastrampoline_jll")
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat = "1.8", preferred_gcc_version=v"6")
