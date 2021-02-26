# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "bliss"
version = v"0.77.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://users.aalto.fi/~tjunttil/bliss/downloads/bliss-0.77.zip", "acc8b98034f30fad24c897f365abd866c13d9f1bb207e398d0caf136875972a4"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd bliss-*
if [[ "${target}" == *mingw* ]]; then
  atomic_patch -p1 ../patches/notimer.patch
fi
# build with GMP and store this information
cd build
cmake -DUSE_GMP=on ..
make -j${nproc}
mkdir -p $prefix/include/bliss
mkdir -p $libdir
install -p -m 0644 -t $prefix/include/bliss ../*.hh
install -p libbliss.$dlext $libdir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libbliss", :libbliss),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.1.2"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
