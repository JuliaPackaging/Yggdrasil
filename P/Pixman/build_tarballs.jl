using BinaryBuilder

# Collection of sources required to build Pixman
name = "Pixman"
version = v"0.42.2"

sources = [
    ArchiveSource("https://www.cairographics.org/releases/pixman-$(version).tar.gz",
                  "ea1480efada2fd948bc75366f7c349e1c96d3297d09a3fe62626e38e234a625e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pixman-*/

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libpixman-1", :libpixman)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6", julia_compat="1.6")
