# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

const name = "libcgal_julia"
const version = v"0.8.0"

# Collection of sources required to build CGAL
const sources = [
    GitSource("https://github.com/rgcv/libcgal-julia.git",
              "ce3b4312d8ba161d85ff6bd2c4aed788f5523613"),
    # julia binaries
    ArchiveSource("https://julialang-s3.julialang.org/bin/linux/x64/1.3/julia-1.3.1-linux-x86_64.tar.gz",
                  "faa707c8343780a6fe5eaf13490355e8190acf8e2c189b9e7ecbddb0fa2643ad"; unpack_target="julia-x86_64-linux-gnu"),
    ArchiveSource("https://github.com/Gnimuc/JuliaBuilder/releases/download/v1.3.0/julia-1.3.0-x86_64-apple-darwin14.tar.gz",
                  "f2e5359f03314656c06e2a0a28a497f62e78f027dbe7f5155a5710b4914439b1"; unpack_target="julia-x86_64-apple-darwin14"),
    ArchiveSource("https://github.com/Gnimuc/JuliaBuilder/releases/download/v1.3.0/julia-1.3.0-x86_64-w64-mingw32.tar.gz",
                  "c7b2db68156150d0e882e98e39269301d7bf56660f4fc2e38ed2734a7a8d1551"; unpack_target="julia-x86_64-w64-mingw32"),
]

# Dependencies that must be installed before this package can be built
const dependencies = [
    Dependency("CGAL_jll"),
    Dependency("libcxxwrap_julia_jll"),
]

# Bash recipe for building across all platforms
const script = raw"""
## pre-build setup
# exit on error
set -eu

## "find" julia
case $target in
  x86_64-linux-gnu)
    Julia_PREFIX=${WORKSPACE}/srcdir/julia-$target/julia-1.3.1
    ;;
  x86_64-apple-darwin14|x86_64-w64-mingw32)
    Julia_PREFIX=${WORKSPACE}/srcdir/julia-$target/juliabin
    ;;
esac

## configure build
cmake libcgal-julia*/ -B build \
  `# cmake specific` \
  -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TARGET_TOOLCHAIN" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_FIND_ROOT_PATH="$prefix" \
  -DCMAKE_INSTALL_PREFIX="$prefix" \
  `# tell libcxxwrap-julia where julia is` \
  -DJulia_PREFIX="$Julia_PREFIX"

## and away we go..
VERBOSE=ON cmake --build build --config Release --target install -- -j$nproc

install_license libcgal-julia*/LICENSE

# HACK: Apparently, this isn't a simple build system anymore..
case $target in
  *mingw32*) mv "$prefix/lib/"*.dll "$prefix/bin" ;;
esac
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
const platforms = [
    Linux(:x86_64, libc=:glibc),
    MacOS(:x86_64),
    Windows(:x86_64),
] |> expand_cxxstring_abis

# The products that we will ensure are always built
const products = [
    LibraryProduct("libcgal_julia_exact", :libcgal_julia_exact),
    LibraryProduct("libcgal_julia_inexact", :libcgal_julia_inexact),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7")

