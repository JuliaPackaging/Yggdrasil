# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name     = "CGAL"
rversion = "5.3"
version  = VersionNumber(rversion)

# Collection of sources required to build CGAL
sources = [
    ArchiveSource("https://github.com/CGAL/cgal/releases/download/v$rversion/CGAL-$rversion.tar.xz",
                  "2c242e3f27655bc80b34e2fa5e32187a46003d2d9cd7dbec8fbcbc342cea2fb6"),
]

# Bash recipe for building across all platforms
script = raw"""
## pre-build setup
# exit on error
set -eu

cmake -B build \
  `# cmake specific` \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_FIND_ROOT_PATH=$prefix \
  -DCMAKE_INSTALL_PREFIX=$prefix \
  -DCMAKE_TOOLCHAIN_FILE=$CMAKE_TARGET_TOOLCHAIN \
  CGAL-*/

## and away we go..
cmake --build build --config Release --target install -- -j$nproc
install_license CGAL-*/LICENSE*
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
    Dependency("boost_jll"; compat="=1.71.0"),
    Dependency("GMP_jll"; compat="6.1.2"),
    Dependency("MPFR_jll"; compat="4.0.2"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"9")
