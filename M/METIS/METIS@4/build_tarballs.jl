using BinaryBuilder, Pkg

name = "METIS"
version = v"4.0.3"

# Collection of sources required to build METIS
sources = [
    ArchiveSource("http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/OLD/metis-$(version).tar.gz",
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
make -j${nproc} COPTIONS="${COPTIONS}"
cd ..

# We copy the .a files into ${prefix}/lib since the main purpose is to link them in other builds.
# Specifically this is in a separate location than the typical location for libraries on Windows.
mkdir -p ${prefix}/lib
mv libmetis.a ${prefix}/lib
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    Product("lib/libmetis.a", :libmetis_a)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"6")
