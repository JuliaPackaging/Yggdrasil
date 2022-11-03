# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "gfm"
version = v"0.29.6"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/github/cmark-gfm.git", "9d57d8a23142b316282bdfc954cb0ecda40a8655")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd $WORKSPACE/srcdir/cmark-gfm
mkdir build
cd build
cmake ../ -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcmark-gfm", :libgfm),
    LibraryProduct("libcmark-gfm-extensions", :libgfm_extensions),
    ExecutableProduct("cmark-gfm", :gfm)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
