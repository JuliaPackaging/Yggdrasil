# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MPSolve"
version = v"3.2.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/robol/MPSolve.git", "65be6767119a3df911943d7aaacdad4646fa6173")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/MPSolve/
export CPPFLAGS="-I${prefix}/include"
./autogen.sh 
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
cd src/libmps/
make
make install
exit
"""

platforms = supported_platforms() 
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libmps", :libmps)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
