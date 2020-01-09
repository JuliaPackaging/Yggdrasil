# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

const name = "CGAL"
const version = v"5"

majorminor(v::VersionNumber) = "$(v.major).$(v.minor)"
const sversion = majorminor(version)

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
]

# Bash recipe for building across all platforms
const script = raw"""
## pre-build setup
# exit on error
set -eu

# check c++ standard reported by the compiler
# CGAL uses CMake's try_run to check if it needs to link with Boost.Thread
# depending on the c++ standard supported by the compiler.
__cplusplus=$($CXX -x c++ -dM -E - </dev/null | grep __cplusplus | grep -o '[0-9]*')

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
  -DWITH_CGAL_ImageIO=OFF \
  -DWITH_CGAL_Qt5=OFF \
  `# 'try_run' won't run the produced executable in a cross-compilation` \
  `# environment. Hence, this is required` \
  -DCGAL_test_cpp_version_RUN_RES__TRYRUN_OUTPUT=$__cplusplus

## and away we go..
cmake --build . --config Release --target install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
const platforms = supported_platforms()
# The products that we will ensure are always built
const products = [
    LibraryProduct("libCGAL", :libCGAL),
    LibraryProduct("libCGAL_Core", :libCGAL_Core),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5")
