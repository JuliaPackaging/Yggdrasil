# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "BPNET"
version = v"0.0.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/cometscome/BPNET.git", "207fd1d739b8cadcf243fc1bd7e1e8d7d28af392"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cd BPNET/
mkdir build
cd build/
cmake ..
make
cp bin/*.x $prefix/
cp lib/* $prefix/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("trainbin2ASCII.x", :bpnet_trainbin2ASCII),
    ExecutableProduct("bpnet_predict.x", :bpnet_predict),
    ExecutableProduct("nnASCII2bin.x", :bpnet_nnASCII2bin),
    ExecutableProduct("bpnet_generate.x", :bpnet_generate)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"13.2.0")
