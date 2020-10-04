# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
import Pkg: PackageSpec

const name = "libsingular_julia"
const version = v"0.2.0"

# Collection of sources required to build libsingular-julia
const sources = [
    ArchiveSource("https://github.com/oscar-system/libsingular-julia/archive/v$(version).tar.gz",
                  "ee4e5ef96caf9d18553600d87f922e5d40cb1c7d30a1697c92b23b493498db1a"),
]

# Bash recipe for building across all platforms
const script = raw"""
# remove $libdir from LD_LIBRARY_PATH as this causes issues with perl
if [[ -n "$LD_LIBRARY_PATH" ]]; then
LD_LIBRARY_PATH=$(echo -n $LD_LIBRARY_PATH | sed -e "s|[:^]$libdir\w*|:|g")
fi

cmake libsingular-j*/ -B build \
   -DJulia_PREFIX="$prefix" \
   -DCMAKE_INSTALL_PREFIX="$prefix" \
   -DCMAKE_FIND_ROOT_PATH="$prefix" \
   -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
   -DCMAKE_CXX_STANDARD=14 \
   -DCMAKE_BUILD_TYPE=Release

VERBOSE=ON cmake --build build --config Release --target install -- -j${nproc}

install_license $WORKSPACE/srcdir/libsingular-j*/LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
const platforms = expand_cxxstring_abis([
    Linux(:x86_64; libc=:glibc, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    MacOS(:x86_64; compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    #Linux(:i686, libc=:glibc; compiler_abi=CompilerABI(cxxstring_abi=:cxx11)), # Wrapper code is buggy
    #FreeBSD(:x86_64, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
])

#platforms = supported_platforms()
#platforms = filter!(p -> !Sys.iswindows(p), platforms)
#platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
const products = [
    LibraryProduct("libsingular_julia", :libsingular_julia),
]

# Dependencies that must be installed before this package can be built
const dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    BuildDependency(PackageSpec(name="Julia_jll", version="v1.4.1")),
    Dependency("libcxxwrap_julia_jll"),
    Dependency("Singular_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7")
