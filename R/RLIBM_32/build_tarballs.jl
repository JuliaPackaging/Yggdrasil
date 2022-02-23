# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "RLIBM_32"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/rutgers-apl/rlibm-32.git",
              "44560acbd2ee22242989bdac259ad3665fa85d06"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/rlibm-32*
make -f ../Makefile -j${nproc}
make -f ../Makefile install
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("floatMathLib", :floatMathLib)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
