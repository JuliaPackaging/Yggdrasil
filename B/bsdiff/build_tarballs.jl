# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "bsdiff"
version = v"4.3.0"

# Collection of sources required to complete build
sources = [
    FileSource("https://github.com/mendsley/bsdiff/archive/64ad986cb7bfa8b9145a2d48cd95986660b35d53.tar.gz", "1181466689aa224f4a2dd2376820588c67d20f4f0d50055339fcb171fb877a29"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd bsdiff-64ad986cb7bfa8b9145a2d48cd95986660b35d53/
./autogen.sh 
export CPPFLAGS="-I${prefix}/include"
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# Disable Windows for now, as there are many BSD-isms in the source code
# that we don't want to bother to patch out.  Things like err.h and whatnot.
platforms = filter(p -> !isa(p, Windows), supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("bspatch", :bspatch),
    ExecutableProduct("bsdiff", :bsdiff)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Bzip2_jll", uuid="6e34b625-4abd-537c-b88f-471c36dfa7a0")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
