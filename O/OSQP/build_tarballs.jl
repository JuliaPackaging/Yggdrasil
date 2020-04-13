# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OSQP"
version = v"0.6.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://dl.bintray.com/bstellato/generic/OSQP/0.6.0/osqp-0.6.0.tar.gz", "79ae6905a71bc8241f75733adfe6a74114aa7fff1e89e0d5c88a1d1e1cc50165")
]

# Bash recipe for building across all platforms
script = raw"""
MKL_SHARED_LIB_DIR=$libdir
cd $WORKSPACE/srcdir
cd osqp-*/
mkdir build
cd build/
cmake -DENABLE_MKL_PARDISO=ON -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libqdldl", :qdldl),
    LibraryProduct("libosqp", :osqp)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("MKL_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
