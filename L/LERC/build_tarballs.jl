# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LERC"
version = v"3.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/Esri/lerc/archive/refs/tags/v$(version.major).$(version.minor).tar.gz", "8c0148f5c22d823eff7b2c999b0781f8095e49a7d3195f13c68c5541dd5740a1")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lerc-*

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release

make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libLerc", :libLerc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
