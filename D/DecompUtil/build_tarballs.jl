# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "DecompUtil"
version = v"0.1.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/dev10110/DecompUtil_C.git", "8ecb3b66a57d293508716105661edc48b9d4e9a4")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/DecompUtil_C
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release .. 
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p->arch(p)=="powerpc64le")

# The products that we will ensure are always built
products = [
    LibraryProduct("libdecomputil", :libdecomputil)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Eigen_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
