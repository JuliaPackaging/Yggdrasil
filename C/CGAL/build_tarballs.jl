# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name    = "CGAL"
version = v"5.0.2"


# Collection of sources required to build CGAL
sources = [
    ArchiveSource("https://github.com/CGAL/cgal/releases/download/releases%2FCGAL-$version/CGAL-$version.tar.xz",
                  "bb3594ba390735404f0972ece301f369b1ff12646ad25e48056b4d49c976e1fa"),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("boost_jll"),
    Dependency("GMP_jll"),
    Dependency("MPFR_jll"),
    Dependency("Zlib_jll"),
]

# Bash recipe for building across all platforms
script = raw"""
## pre-build setup
# exit on error
set -eu

## configure build
cmake CGAL*/ -B build \
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
cmake --build build --config Release --target install -- -j$nproc
install_license CGAL*/LICENSE*
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

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7")
