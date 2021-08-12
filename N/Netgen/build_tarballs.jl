# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Netgen"
version = v"1.5.199"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/RTimothyEdwards/netgen.git", "168e5502a1aeba4068beaa0437837ae748877ca8")
]

dependencies = [
]

# Bash recipe for building across all platforms
script = raw"""
cd netgen
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> !Sys.iswindows(p), supported_platforms(;experimental=true))
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = Product[
	ExecutableProduct("netgen", :netgen),
    ExecutableProduct("inetcomp", :inetcomp),
    ExecutableProduct("ntk2xnf", :ntk2xnf),
    ExecutableProduct("ntk2adl", :ntk2adl),
    ExecutableProduct("netcomp", :netcomp)
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
