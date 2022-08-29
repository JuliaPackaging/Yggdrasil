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
upstream_version = v"5.4.1"
version_offset = v"0.0.0" # reset to 0.0.0 once the upstream version changes
version = VersionNumber(upstream_version.major * 100 + version_offset.major,
                        upstream_version.minor * 100 + version_offset.minor,
                        upstream_version.patch * 100 + version_offset.patch)
upstream_version
sources = [
  ArchiveSource("https://graal.ens-lyon.fr/MUMPS/MUMPS_$(upstream_version).tar.gz","93034a1a9fe0876307136dcde7e98e9086e199de76f1c47da822e7d4de987fa8"), # v5.4.1
  # ArchiveSource("https://graal.ens-lyon.fr/MUMPS/MUMPS_$(upstream_version).tar.gz","1abff294fa47ee4cfd50dfd5c595942b72ebfcedce08142a75a99ab35014fa15"), # v5.5.1
  DirectorySource("./bundled")
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
            OPTL=-O3
            OPTC=-O3
            CDEFS=-DAdd_
            LMETISDIR=${libdir}
            IMETIS=-I${includedir}
            LMETIS="-L${libdir} -lmetis"
            ORDERINGSF="-Dpord -Dmetis"
            CC="$CC -fPIC ${CFLAGS[@]}"
            FC="gfortran -fPIC ${FFLAGS[@]}"
            FL="gfortran -fPIC"
            RANLIB="echo"
            LIBBLAS="-L${libdir} -lblastrampoline"
            LAPACK="-L${libdir} -lblastrampoline")

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
libs=(-L${libdir} -lmetis -lblastrampoline -lmpiseq)
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

cp include/*.h ${includedir}
cp libseq/*.h ${includedir}
"""

# Recipe for v5.5.1
script2 = raw"""
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
            OPTL=-O3
            OPTC=-O3
            CDEFS=-DAdd_
            LMETISDIR=${libdir}
            IMETIS=-I${includedir}
            LMETIS="-L${libdir} -lmetis"
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
