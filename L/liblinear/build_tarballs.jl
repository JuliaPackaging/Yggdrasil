# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "liblinear"
version = v"2.30.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/cjlin1/liblinear/archive/v230.tar.gz", "9b57710078206d4dbbe75e9015d4cf7fabe4464013fe0e89b8a2fe40038f8f51"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cd liblinear-230/
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
