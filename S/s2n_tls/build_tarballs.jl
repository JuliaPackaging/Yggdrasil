# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "s2n_tls"
version = v"1.5.14"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/aws/s2n-tls.git", "4ed4f1a658b70559ec4a18e91d1319daa14b0610"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/s2n-tls
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_TESTING=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p->Sys.iswindows(p) || Sys.isapple(p))

# The products that we will ensure are always built
products = [
    LibraryProduct("libs2n", :libs2n),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("aws_lc_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")

# build trigger: 1
