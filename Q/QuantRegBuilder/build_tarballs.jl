# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "QuantRegBuilder"
version = v"0.1.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/fogarty-ben/QuantReg.jl-Builder.git", "7800e5d4e4c2dfd89e8d9076d764b11a51f55081")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd QuantReg.jl-Builder/
mkdir -p ${libdir}
gfortran -fPIC -shared -std=legacy rqbr.f -o ${libdir}/librqbr.${dlext} 
gfortran -fPIC -shared -std=legacy rqfnb.f -o ${libdir}/librqfnb.${dlext} 
install_license LICENSE
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("librqfnb", :librqfnb),
    LibraryProduct("librqbr", :librqbr)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
