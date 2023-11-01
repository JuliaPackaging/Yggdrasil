# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libCEED"
version = v"0.12.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/CEED/libCEED/archive/v$(version).tar.gz",
                  "2d94c218f6ab1bed072d11b70b0a0e70a5720fdf3d61db924e89909424a2f93e")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libCEED-*
make -j${nproc} MEMCHK=0 CC_VENDOR=gcc
make install MEMCHK=0 CC_VENDOR=gcc
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(exclude=Sys.iswindows)

# The products that we will ensure are always built
products = [
    LibraryProduct("libceed", :libceed)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
