# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "bdwgc"
version = v"8.2.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/ivmai/bdwgc/releases/download/v$(version)/gc-$(version).tar.gz", "f30107bcb062e0920a790ffffa56d9512348546859364c23a14be264b38836a0"),
    ArchiveSource("https://github.com/ivmai/libatomic_ops/releases/download/v7.6.14/libatomic_ops-7.6.14.tar.gz", "390f244d424714735b7050d056567615b3b8f29008a663c262fb548f1802d292")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gc-8.2.2/
mv ../libatomic_ops-7.6.14/ libatomic_ops
./autogen.sh 
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcord", :libcord),
    LibraryProduct("libgc", :libgc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
