# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name     = "CGAL"
rversion = "5.3"
version  = VersionNumber(rversion)

# Collection of sources required to build CGAL
sources = [
    ArchiveSource("https://github.com/CGAL/cgal/releases/download/v$rversion/CGAL-$rversion-library.tar.xz",
                  "1c9c32814eb9b0abfd368c8145194b49d7c6ade76eec613b1eac6ebb93470bdb"),
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
  `# cgal specific` \
  -DWITH_CGAL_Core=ON \
  -DWITH_CGAL_ImageIO=ON \
  -DWITH_CGAL_Qt5=OFF \
  CGAL-*/

## and away we go..
cmake --build build --config Release --target install -- -j$nproc
install_license CGAL-*/LICENSE*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
# CGAL is, as of 5.0, a header-only library, removing support for lib
# compilation in 5.3
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Essential dependencies
    Dependency("boost_jll"; compat="=1.71.0"),
    Dependency("GMP_jll", v"6.1.2"; compat=">=4.2"),
    Dependency("MPFR_jll", v"4.0.2"; compat=">=2.2.1"),
    Dependency("Zlib_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8")
