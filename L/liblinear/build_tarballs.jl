# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "liblinear"
version = v"2.30.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/cjlin1/liblinear", "8dc206b782e07676dc0d00678bedd295ce85acf3"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cd liblinear/
mkdir -p ${prefix}/bin
mkdir -p ${prefix}/lib
if [[ "${target}" == *-freebsd* ]] || [[ "${target}" == *-apple-* ]]; then
    CC=gcc
    CXX=g++
fi
make 
make lib
cp train${exeext} ${bindir}
cp predict${exeext} ${bindir}
cp liblinear.${dlext} ${libdir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("liblinear", :liblinear),
    ExecutableProduct("train", :train),
    ExecutableProduct("predict", :predict)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
