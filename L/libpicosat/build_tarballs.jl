# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libpicosat"
version = v"965.0.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/JuliaLang/PicoSAT.git", "be39918064860d3887b4175a68752539803142b3"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/PicoSAT
cp ../{Makefile,config.h} .
make libpicosat.${dlext}
make install
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libpicosat", :libpicosat),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5.2.0", julia_compat="1.6")

