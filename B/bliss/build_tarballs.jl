# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "bliss"
version = v"0.73.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://www.tcs.hut.fi/Software/bliss/bliss-0.73.zip", "f57bf32804140cad58b1240b804e0dbd68f7e6bf67eba8e0c0fa3a62fd7f0f84"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd bliss-0.73
if [[ "${target}" == *mingw* ]]; then
  atomic_patch -p1 ../patches/notimer.patch
fi
# build with GMP and store this information
sed -i -e 's/^namespace bliss/#define BLISS_USE_GMP\n\nnamespace bliss/' defs.hh
make -j${nproc} lib_gmp CFLAGS="-I$prefix/include -O3 -fPIC -I." LDFLAGS="$LDFLAGS -L$libdir" CC="$CXX"
# there is no target for a shared library
$CXX -shared -o libbliss.$dlext *.og $LDFLAGS -L$libdir -lgmp
mkdir -p $prefix/include/bliss
mkdir -p $libdir
install -p -m 0644 -t $prefix/include/bliss *.hh
install -p libbliss.$dlext $libdir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libbliss", :libbliss)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.1.2"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
