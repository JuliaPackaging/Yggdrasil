# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Taskflow"
version = v"3.3.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/taskflow/taskflow/archive/refs/tags/v$(version).tar.gz", "66b891f706ba99a5ca5ed239d520ad6943ebe94728d1c89e07a939615a6488ef"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/taskflow-*
mkdir build && cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]


# The products that we will ensure are always built
#taskflow is header only, so no products
products = Product[]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
#explicitly specifies gcc7 as lower bound in top level CMakeLists.txt, README mentions gcc8 as lower bound?
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7")
