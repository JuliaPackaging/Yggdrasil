# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Giflib"
version = v"5.2.2"

# Collection of sources required to build Giflib
sources = [
    ArchiveSource("https://downloads.sourceforge.net/project/giflib/giflib-$(version).tar.gz",
                  "be7ffbd057cadebe2aa144542fd90c6838c6a083b5e8a9048b8ee3b66b29d5fb"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/giflib-*/
# Apply patch to make it possible to build for non Linux-like platforms.
# Adapted from also https://sourceforge.net/p/giflib/bugs/133/
atomic_patch -p1 ../patches/makefile.patch
# We cannot build in parallel, building `libutil` fails.
make
make install
rm "${libdir}/libgif.a"
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libgif", :libgif),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

# Build trigger: 1
