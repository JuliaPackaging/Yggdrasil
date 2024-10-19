# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "bsdiff_classic"
version = v"4.3.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://deb.debian.org/debian/pool/main/b/bsdiff/bsdiff_4.3.orig.tar.gz", "18821588b2dc5bf159aa37d3bcb7b885d85ffd1e19f23a0c57a58723fea85f48"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/bsdiff-4.3
perl -i -ple '$_ = "#include <sys/types.h>\n" . $_ if $. == 31' bspatch.c
cc -O3 -lbz2 -I"${prefix}/include" bsdiff.c -o bsdiff
cc -O3 -lbz2 -I"${prefix}/include" bspatch.c -o bspatch
install bsdiff bspatch "${bindir}"
"""

# Disable Windows for now, as there are many BSD-isms in the source code
# that we don't want to bother to patch out.  Things like err.h and whatnot.
platforms = filter(!Sys.iswindows, supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("bspatch", :bspatch),
    ExecutableProduct("bsdiff", :bsdiff)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Bzip2_jll", v"1.0.8"; compat="1.0.8"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
