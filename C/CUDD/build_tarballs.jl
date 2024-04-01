# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CUDD"
version = v"3.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://davidkebo.com/source/cudd_versions/cudd-$(version).tar.gz", "b8e966b4562c96a03e7fbea239729587d7b395d53cadcc39a7203b49cf7eeb69")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd cudd-3.0.0/
sed -i 's/cross_compiling=no/cross_compiling=yes/' configure
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-shared --enable-obj --enable-silent-rules
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libcudd", "libcudd-3-0-0"], :libcudd)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
