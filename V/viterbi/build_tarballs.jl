# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "viterbi"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/zsoerenm/viterbi.git", "5a9411d48708adcb84ff2250fd3fa7b1a2c131fe")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/viterbi
make TARGET="libviterbi.${dlext}"
install -Dvm 755 "libviterbi.${dlext}" "${libdir}/libviterbi.${dlext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libviterbi", :libviterbi)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
