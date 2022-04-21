
# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FLEXPART"
version = v"10.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://www.flexpart.eu/gitmob/flexpart", "3d7eebf7c4909f59db5ec32c524f88fb846e9fe5"),
    GitSource("https://www.flexpart.eu/gitmob/flex_extract", "e0005c99ac81d12faa45a8ff799debbd592b0dc0"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
# The flexpart-parmod.patch modify some parameters to extend the size of 
# the meteorological input files and the maximum number of particules that FLEXPART can handle.
script = raw"""
cd flexpart
atomic_patch -p1 /workspace/srcdir/patches/flexpart-makefile.patch
atomic_patch -p1 /workspace/srcdir/patches/flexpart-parmod.patch
cd src
make ncf=yes
cp FLEXPART $bindir

cd ../../flex_extract
atomic_patch -p1 /workspace/srcdir/patches/flexextract-makefile.patch
cd Source/Fortran/
make -f makefile_local_gfortran
cp calc_etadot_fast.out $bindir/calc_etadot
"""

platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("FLEXPART", :FLEXPART),
    ExecutableProduct("calc_etadot", :calc_etadot),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("eccodes_jll"),
    Dependency("Emoslib_jll"),
    Dependency("NetCDFF_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
julia_compat = "1.6")
