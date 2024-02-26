# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name     = "CGAL"
version  = v"5.5.2"

# Collection of sources required to build CGAL
sources = [
    GitSource("https://github.com/CGAL/cgal.git",
                  "8a3184a1a82c3e7d737656bfa4950471c369a4b9"),
]

# Bash recipe for building across all platforms
script = raw"""
cmake -B build \
  `# cmake specific` \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_FIND_ROOT_PATH=$prefix \
  -DCMAKE_INSTALL_PREFIX=$prefix \
  -DCMAKE_TOOLCHAIN_FILE=$CMAKE_TARGET_TOOLCHAIN \
  cgal/

## and away we go..
cmake --build build --config Release --target install -- -j$nproc
install_license cgal/LICENSE*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
# CGAL is, as of 5.0, a header-only library, removing support for lib
# compilation in 5.3
products = Product[]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Essential dependencies
    Dependency("boost_jll"; compat="=1.76.0"),
    Dependency("GMP_jll"; compat="6.2.1"),
    Dependency("MPFR_jll"; compat="4.1.0"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"9")
