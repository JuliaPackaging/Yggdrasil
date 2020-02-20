using BinaryBuilder

name = "METIS"
version = v"4.0.3"

# Collection of sources required to build METIS
sources = [
    ArchiveSource("http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/OLD/metis-4.0.3.tar.gz",
                  "5efa35de80703c1b2c4d0de080fafbcf4e0d363a21149a1ad2f96e0144841a55"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
all_load="--whole-archive"
noall_load="--no-whole-archive"
COPTIONS="-fPIC"
if [[ "${target}" == *-apple-* ]]; then
  all_load="-all_load"
  noall_load="-noall_load"
fi
if [[ "${target}" == *-mingw* ]]; then
  COPTIONS="${COPTIONS} -D__VC__"  # to resolve missing srand48/drand48 symbols
fi

# build libmetis.a
cd $WORKSPACE/srcdir/metis-4.0.3
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
  atomic_patch -p1 ${f}
done
cd Lib
make -j${nproc} COPTIONS="${COPTIONS}"
cd ..

# make a shared lib
cc -fPIC -shared -Wl,${all_load} libmetis.a -Wl,${noall_load} -o libmetis.${dlext}

mkdir -p ${libdir}
mv libmetis.${dlext} ${libdir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmetis", :libmetis),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
