# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

const name = "libcgal_julia"

version = v"0.5.0"

# Collection of sources required to build CGAL
const sources = [
    "https://github.com/rgcv/libcgal-julia.git" =>
        "d5e3d823dd6b0f210736ef93e7bc62c7e1d5b414"
]

# Dependencies that must be installed before this package can be built
const dependencies = [
    "CGAL_jll",
    "libcxxwrap_julia_jll",
]

# Bash recipe for building across all platforms
const script = raw"""
## pre-build setup
# exit on error
set -eu

# HACK: download julia..
curl -Lo julia.tar.gz https://github.com/JuliaPackaging/JuliaBuilder/releases/download/v1.0.0-2/julia-1.0.0-$target.tar.gz
mkdir julia && tar xf julia.tar.gz -C julia
Julia_PREFIX="$PWD/julia"

## configure build
mkdir -p build && cd build

cmake ../libcgal-julia*/ \
  `# cmake specific` \
  -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TARGET_TOOLCHAIN" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_FLAGS="-march=x86-64" \
  -DCMAKE_FIND_ROOT_PATH="$prefix" \
  -DCMAKE_INSTALL_PREFIX="$prefix" \
  `# tell libcxxwrap-julia where julia is` \
  -DJulia_PREFIX="$Julia_PREFIX"

## and away we go..
VERBOSE=ON cmake --build . --config Release --target install -- -j$nproc

install_license ../libcgal-julia*/LICENSE

# HACK: Apparently, this isn't a simple build system anymore..
case $target in
  *mingw32*) mv "$prefix/lib/"*.dll "$prefix/bin" ;;
esac
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
const platforms = [
    Linux(:x86_64, libc=:glibc),
    Windows(:i686),
    Windows(:x86_64),
    MacOS(:x86_64),
] |> expand_cxxstring_abis

# The products that we will ensure are always built
const products = [
    LibraryProduct("libcgal_julia_exact", :libcgal_julia_exact),
    LibraryProduct("libcgal_julia_inexact", :libcgal_julia_inexact),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7")
