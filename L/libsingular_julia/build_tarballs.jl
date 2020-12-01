# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
import Pkg: PackageSpec

const name = "libsingular_julia"
const version = v"0.2.2"

# Collection of sources required to build libsingular-julia
const sources = [
    ArchiveSource("https://github.com/oscar-system/libsingular-julia/archive/v$(version).tar.gz",
                  "7de191972c8f116e70715808c96857de64140dd610aeb7d0b69fc869cf49593a"),
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
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi = "cxx11"),
    Platform("x86_64", "macos"; cxxstring_abi = "cxx11"),
    #Platform("i686", "linux"; libc="glibc", cxxstring_abi="cxx11"), # Wrapper code is buggy
    #Platform("x86_64", "freebsd"; cxxstring_abi = "cxx11"),
])

#platforms = supported_platforms()
#platforms = filter!(!Sys.iswindows, platforms)
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
