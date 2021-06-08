# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FGlT"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/fcdimitr/fglt.git", "b91e1b3f4ed05eca69f342f7319faedb9d358257")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd fglt/
meson --cross-file=${MESON_TARGET_TOOLCHAIN} build
cd build/
ninja
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# FGlT contains std::string values!  This causes incompatibilities across the GCC 4/5 version boundary.
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libfglt", :libfglt)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
