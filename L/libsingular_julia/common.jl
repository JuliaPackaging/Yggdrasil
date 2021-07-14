# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
import Pkg: PackageSpec
import Pkg.Types: VersionSpec

name = "libsingular_julia"
version = VersionNumber(0, 15, julia_version.minor)

# Collection of sources required to build libsingular-julia
sources = [
    GitSource("https://github.com/oscar-system/libsingular-julia.git", "09099804e5c191dfb77f360807876062ed9c1cc0"),
]

# Bash recipe for building across all platforms
script = raw"""
cd libsingular-julia
cmake . -B build \
   -DJulia_PREFIX="$prefix" \
   -DSingular_PREFIX="$prefix" \
   -DCMAKE_INSTALL_PREFIX="$prefix" \
   -DCMAKE_FIND_ROOT_PATH="$prefix" \
   -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
   -DCMAKE_CXX_STANDARD=14 \
   -DCMAKE_BUILD_TYPE=Release

VERBOSE=ON cmake --build build --config Release --target install -- -j${nproc}

install_license LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")
platforms = libjulia_platforms(julia_version)
filter!(!Sys.iswindows, platforms) # Singular does not support Windows
# disable experimental platforms for now: support would require rebuilding
# all dependencies; and it would require them to have julia_compat >= 1.6
# (so either we drop support for all older Julia versions, or have to build
# those dependencies twice)
filter!(p -> !(Sys.isapple(p) && arch(p) == "aarch64"), platforms) # M1
filter!(p -> arch(p) != "armv6l", platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libsingular_julia", :libsingular_julia),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="libjulia_jll", version=julia_version)),
    BuildDependency(PackageSpec(name="GMP_jll", version=v"6.1.2")),
    BuildDependency(PackageSpec(name="MPFR_jll", version=v"4.0.2")),
    Dependency("libcxxwrap_julia_jll", VersionNumber(0, 8, julia_version.minor)),
    Dependency("Singular_jll", compat = "~402.000.102"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"8",
    julia_compat = "$(julia_version.major).$(julia_version.minor)")
