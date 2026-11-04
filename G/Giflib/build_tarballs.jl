# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Giflib"
version = v"6.1.3"

# Collection of sources required to build Giflib
sources = [
    ArchiveSource("https://sourceforge.net/projects/giflib/files/giflib-$(version.major).x/giflib-$(version).tar.gz",
                  "b65b66b99f0424b93525f987386f22fc5efb9da2bfc92ad4a532249aaffbab0e"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/giflib-*

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
