# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libdeflate"
version_string = "1.18"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/ebiggers/libdeflate",
        "495fee110ebb48a5eb63b75fd67e42b2955871e2"
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libdeflate
make PROG_SUFFIX=$exeext PREFIX=${prefix} LIBDIR=${libdir} DISABLE_ZLIB=true
make PROG_SUFFIX=$exeext PREFIX=${prefix} LIBDIR=${libdir} install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libdeflate", :libdeflate)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
