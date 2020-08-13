# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libdeflate"
version = v"1.6.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/ebiggers/libdeflate/archive/v1.6.tar.gz", "60748f3f7b22dae846bc489b22a4f1b75eab052bf403dd8e16c8279f16f5171e"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd libdeflate-1.6/
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/fix_makefile.patch
make PROG_SUFFIX=$exeext PREFIX=${prefix} LIBDIR=${libdir} DISABLE_ZLIB=true install
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
