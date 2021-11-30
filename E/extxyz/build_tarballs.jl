# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "extxyz"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/libAtoms/extxyz", "47a449e69fa9fa0cc99d0acad3a4a4925c363495")
]

# Bash recipe for building across all platforms
script = raw"""
export CFLAGS="-std=c99"
cd $WORKSPACE/srcdir/extxyz
make -C libextxyz libextxyz.${dlext}
make -C libextxyz install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)


# The products that we will ensure are always built
products = [
    LibraryProduct("libextxyz", :libextxyz)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="PCRE2_jll", uuid="efcefdf7-47ab-520b-bdef-62a2eaa19f15")),
    Dependency(PackageSpec(name="libcleri_jll", uuid="cdc7adba-bef8-5cba-a7ee-c792dee3081e"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
