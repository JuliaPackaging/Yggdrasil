# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LibArchive"
version = v"3.4.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/libarchive/libarchive/archive/v3.4.3.tar.gz", "19556c1c67aacdff547fd719729630444dbc7161c63eca661a310676a022bb01")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd libarchive-3.4.3/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libarchive", :libarchive),
    ExecutableProduct("bsdcpio", :bsdcpio),
    ExecutableProduct("bsdtar", :bsdtar),
    ExecutableProduct("bsdcat", :bsdcat)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
