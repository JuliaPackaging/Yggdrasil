# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "bsdiff_endsley"
version = v"4.3.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mendsley/bsdiff.git", "64ad986cb7bfa8b9145a2d48cd95986660b35d53"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/bsdiff
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
    Dependency("Bzip2_jll"; compat="1.0.8"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
