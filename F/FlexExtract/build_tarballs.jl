
# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FlexExtract"
version = v"7.1.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://www.flexpart.eu/gitmob/flex_extract", "e0005c99ac81d12faa45a8ff799debbd592b0dc0"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd flex_extract
atomic_patch -p1 /workspace/srcdir/patches/flexextract-makefile.patch
cd Source/Fortran/
make -f makefile_local_gfortran
cp calc_etadot_fast.out $bindir/calc_etadot
install_license ../../LICENSE.md
"""

# platforms = [
#     Platform("x86_64", "linux"; libc = "glibc")
# ]

platforms = supported_platforms()
# Remove the unsupported platforms
filter!(!Sys.iswindows, platforms)
filter!(!Sys.isapple, platforms)
filter!(!Sys.isfreebsd, platforms)
filter!(p -> libc(p) != "musl", platforms)
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("calc_etadot", :calc_etadot),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("eccodes_jll"),
    BuildDependency("Emoslib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
julia_compat = "1.6")
