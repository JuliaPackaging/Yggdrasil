# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

const name, version = "CGAL", v"5"
const sversion = "$(version.major).$(version.minor)"

# Collection of sources required to build CGAL
const sources = [
    "https://github.com/CGAL/cgal/releases/download/releases%2FCGAL-$sversion/CGAL-$sversion.tar.xz" =>
        "e1e7e932988c5d149aa471c1afd69915b7603b5b31b9b317a0debb20ecd42dcc",
]

# Dependencies that must be installed before this package can be built
const dependencies = [
    "boost_jll",
    "GMP_jll",
    "MPFR_jll",
    "Zlib_jll",
]

# Bash recipe for building across all platforms
const script = raw"""
## pre-build setup
# exit on error
set -eu

## configure build
cd "$WORKSPACE/srcdir"/CGAL-*/
mkdir build && cd build

cmake .. \
  `# cmake specific` \
  -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TARGET_TOOLCHAIN"\
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$prefix" \
  -DCMAKE_FIND_ROOT_PATH="$prefix" \
  `# cgal specific` \
  -DCGAL_HEADER_ONLY=OFF \
  -DWITH_CGAL_Core=ON \
  -DWITH_CGAL_ImageIO=ON \
  -DWITH_CGAL_Qt5=OFF

## and away we go..
cmake --build . --config Release --target install -- -j$nproc
install_license ../LICENSE*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
const platforms = expand_cxxstring_abis(supported_platforms())
# The products that we will ensure are always built
const products = [
    LibraryProduct("libCGAL", :libCGAL),
    LibraryProduct("libCGAL_Core", :libCGAL_Core),
    LibraryProduct("libCGAL_ImageIO", :libCGAL_ImageIO),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5")
