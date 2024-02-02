using BinaryBuilder

name = "VIC5"
version = v"0.1.1"

# Collection of sources required to build
sources = [
    GitSource("https://github.com/CUG-hydro/VIC5.c.git",
    "339d9666ce17e9638e16193c43637e453e3b03ef"), # v0.1.1
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/VIC5.c/vic

target=${libdir}/libvic5_classic.${dlext} make dll
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libvic5_classic", :libvic5_classic),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
