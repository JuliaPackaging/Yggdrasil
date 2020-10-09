# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ISL"
version = v"0.22.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://isl.gforge.inria.fr/isl-0.22.tar.xz", "6c8bc56c477affecba9c59e2c9f026967ac8bad01b51bdd07916db40a517b9fa"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd isl-0.22/
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/isl-0.14.1-no-undefined.patch
autoreconf
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-gmp-prefix=${prefix}
make -j
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libisl", :libisl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.1.2"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
