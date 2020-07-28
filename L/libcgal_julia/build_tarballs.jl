# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
import Pkg: PackageSpec

name = "libcgal_julia"
version = v"0.14"

isyggdrasil = get(ENV, "YGGDRASIL", "") == "true"
rname = "libcgal-julia"

# Collection of sources required to build CGAL
sources = [
    isyggdrasil ?
        GitSource("https://github.com/rgcv/$rname.git",
                  "2e4dbb3fbf94e82960764ce6cbea490fcb46a9cd") :
        DirectorySource(joinpath(ENV["HOME"], "src/github/rgcv/$rname"))
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="Julia_jll", version="v1.4.1")),

    Dependency("CGAL_jll"),
    Dependency("libcxxwrap_julia_jll"),
]

# Bash recipe for building across all platforms
jlcgaldir = ifelse(isyggdrasil, rname, ".")
script = raw"""
## pre-build setup
# exit on error
set -eu

macosflags=
case $target in
  *apple-darwin*)
    macosflags="-DCMAKE_CXX_COMPILER_ID=AppleClang"
    macosflags="$macosflags -DCMAKE_CXX_COMPILER_VERSION=10.0.0"
    macosflags="$macosflags -DCMAKE_CXX_STANDARD_COMPUTED_DEFAULT=11"
    ;;
esac
""" * """
## configure build
cmake $jlcgaldir -B /tmp/build """ * raw"""\
  `# cmake specific` \
  -DCMAKE_TOOLCHAIN_FILE=$CMAKE_TARGET_TOOLCHAIN \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_FIND_ROOT_PATH=$prefix \
  -DCMAKE_INSTALL_PREFIX=$prefix \
  $macosflags \
  `# tell jlcxx where julia is` \
  -DJulia_PREFIX=$prefix

## and away we go..
VERBOSE=ON cmake --build /tmp/build --config Release --target install -- -j$nproc
""" * """
install_license $jlcgaldir/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    FreeBSD(:x86_64; compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    Linux(:aarch64; libc=:glibc, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    # generates plentiful warnings about parameter passing ABI changes, better
    # safe than sorry
    # Linux(:armv7l; libc=:glibc, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    Linux(:i686; libc=:glibc, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    Linux(:x86_64; libc=:glibc, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    MacOS(:x86_64; compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    Windows(:i686; compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    Windows(:x86_64; compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libcgal_julia_exact", :libcgal_julia_exact),
    LibraryProduct("libcgal_julia_inexact", :libcgal_julia_inexact),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7")
