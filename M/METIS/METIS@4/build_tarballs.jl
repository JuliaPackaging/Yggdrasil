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

name = "METIS4"
upstream_version = v"4.0.3"
version_offset = v"0.0.1" # reset to 0.0.0 once the upstream version changes
version = VersionNumber(upstream_version.major * 100 + version_offset.major,
                        upstream_version.minor * 100 + version_offset.minor,
                        upstream_version.patch * 100 + version_offset.patch)

# Collection of sources required to build METIS
sources = [
    ArchiveSource("http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/OLD/metis-$(upstream_version).tar.gz",
                  "5efa35de80703c1b2c4d0de080fafbcf4e0d363a21149a1ad2f96e0144841a55"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
if [[ "${target}" == *-mingw* ]]; then
  COPTIONS="${COPTIONS} -D__VC__"  # to resolve missing srand48/drand48 symbols
fi

# build libmetis.a
cd $WORKSPACE/srcdir/metis-*
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
  atomic_patch -p1 ${f}
done
cd Lib
make -j${nproc} COPTIONS="${COPTIONS} -fPIC"
cd ..

if [[ "${target}" == *apple* ]]; then
    SONAME="-install_name"
else
    SONAME="-soname"
fi

mkdir -p $libdir
mkdir -p $includedir
cp Lib/metis.h $includedir
$CC -shared -Wl,$SONAME,libmetis4.${dlext} $(flagon -Wl,--whole-archive) libmetis.a $(flagon -Wl,--no-whole-archive) -o ${libdir}/libmetis4.${dlext}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmetis4", :libmetis4),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"6")
