using BinaryBuilder

# Collection of sources required to build SHTOOLS
name = "SHTOOLS"
version = v"4.8"
sources = [
    ArchiveSource("https://github.com/SHTOOLS/SHTOOLS/releases/download/v$(version)/SHTOOLS-$(version).tar.gz",
                  "c36fc86810017e544abbfb12f8ddf6f101a1ac8b89856a76d7d9801ffc8dac44"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SHTOOLS-*
perl -pi -e 's/-ffast-math//' Makefile
make fortran
make install PREFIX=$prefix
"""

platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libSHTOOLS", :libSHTOOLS),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("FFTW_jll"),
    Dependency("OpenBLAS_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"5")
