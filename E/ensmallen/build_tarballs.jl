# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ensmallen"
version = v"2.22.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.ensmallen.org/files/ensmallen-$(version).tar.gz", "daf53fe96783043ca33151a3851d054a826fab8d9a173e6bcbbedd4a7eabf5b1")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ensmallen-*
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
#ensmallen is header only, so no products
products = Product[]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="armadillo_jll", uuid="0631256a-41da-5d69-bb72-795e0d5510ec"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
