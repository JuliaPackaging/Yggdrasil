# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "bsdiff_endsley"
version = v"4.3.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/mendsley/bsdiff/archive/64ad986cb7bfa8b9145a2d48cd95986660b35d53.tar.gz", "1181466689aa224f4a2dd2376820588c67d20f4f0d50055339fcb171fb877a29"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/bsdiff-64ad986cb7bfa8b9145a2d48cd95986660b35d53
./autogen.sh 
export CPPFLAGS="-I${prefix}/include"
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
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
    # Future versions of bzip2 should allow a more relaxed compat because the
    # soname of the macOS library shouldn't change at every patch release.
    Dependency("Bzip2_jll", v"1.0.6"; compat="=1.0.6"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
