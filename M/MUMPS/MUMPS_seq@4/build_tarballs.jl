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
upstream_version = v"4.10.0"
version_offset = v"0.0.0" # reset to 0.0.0 once the upstream version changes
version = VersionNumber(upstream_version.major * 100 + version_offset.major,
                        upstream_version.minor * 100 + version_offset.minor,
                        upstream_version.patch * 100 + version_offset.patch)

METIS_version = v"400.000.300"

sources = [
  ArchiveSource("http://mumps.enseeiht.fr/MUMPS_$(upstream_version).tar.gz",
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

FFLAGS=()
if [[ "${target}" == aarch64-apple-* ]]; then
    FFLAGS+=(-fallow-argument-mismatch)
fi

make_args=(OPTF=-O3
            CDEFS=-DAdd_
            LMETISDIR=${prefix}/lib
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
products = [
    FileProduct("lib/libsmumps.a", :libsmumps_a),
    FileProduct("lib/libdmumps.a", :libdmumps_a),
    FileProduct("lib/libcmumps.a", :libcmumps_a),
    FileProduct("lib/libzmumps.a", :libzmumps_a),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(; name = "METIS4_jll",
                                uuid = "40b5814e-7855-5c9f-99f7-a735ce3fdf8b",
                                version = "=$(METIS_version)")),
    BuildDependency("OpenBLAS32_jll"),
    BuildDependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"6")
