# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libdeflate"
version = v"1.8.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/ebiggers/libdeflate/archive/refs/tags/v1.8.tar.gz", 
                  "50711ad4e9d3862f8dfb11b97eb53631a86ee3ce49c0e68ec2b6d059a9662f61"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd libdeflate-*/
make PROG_SUFFIX=$exeext PREFIX=${prefix} LIBDIR=${libdir} DISABLE_ZLIB=true
make PROG_SUFFIX=$exeext PREFIX=${prefix} LIBDIR=${libdir} install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libdeflate", :libdeflate)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
