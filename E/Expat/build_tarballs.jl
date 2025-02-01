# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Expat"
ygg_version = v"2.6.5"
version = "2.6.4" # version built is 2.6.4, bumped to pick up riscv with new jll wrapper

# Collection of sources required to build Expat
sources = [
    ArchiveSource("https://github.com/libexpat/libexpat/releases/download/R_$(version.major)_$(version.minor)_$(version.patch)/expat-$(version).tar.xz",
                  "a695629dae047055b37d50a0ff4776d1d45d0a4c842cf4ccee158441f55ff7ee"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/expat-*/
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
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies; julia_compat="1.6")
