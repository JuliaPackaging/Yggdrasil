# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Expat"
version = v"2.8.3"

# Collection of sources required to build Expat
sources = [
    ArchiveSource("https://github.com/libexpat/libexpat/releases/download/R_$(version.major)_$(version.minor)_$(version.patch)/expat-$(version).tar.xz",
                  "f6256df90c906773d344da084402b7d3e4f22ed41b1a59c989098a83d3ea0c85"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/expat*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libexpat", :libexpat),
    ExecutableProduct("xmlwf", :xmlwf)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
