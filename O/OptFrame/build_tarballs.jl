# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name    = "OptFrame"
version = v"6.0.0"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/OptFrame/OptFrame.git",
        "3b57dcd24bc4dff2abf0ef28010bf736509eefa5",
    )
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/OptFrame/

make optframe_lib

install -Dvm755 build/optframe_lib.so "${libdir}/optframe_lib.${dlext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(
    filter(
        p -> p != Platform("x86_64", "macos"),
        supported_platforms(),
    )
)

# The products that we will ensure are always built
products = [
    LibraryProduct("optframe_lib", :optframe)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"10.2.0")
