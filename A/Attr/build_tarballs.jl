# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Attr"
version = v"2.6.0"

# Collection of sources required to build attr
sources = [
    ArchiveSource("https://download.savannah.gnu.org/releases/attr/attr-$(version).tar.xz",
                  "6c8a2148a7b85043b68492bce43316b0e2e214fc4e628c7ede078e76e216330b"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/attr-*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
install_license doc/COPYING*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(Sys.islinux, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libattr", :attr),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
