# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Attr"
version = v"2.5.1"

# Collection of sources required to build attr
sources = [
    ArchiveSource("https://download.savannah.gnu.org/releases/attr/attr-$(version).tar.xz",
                  "db448a626f9313a1a970d636767316a8da32aede70518b8050fa0de7947adc32"),
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
# platforms are passed in on the command line.  We are manually disabling
# many platforms that do not seem to work.
platforms = filter!(Sys.islinux, supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct("libattr", :attr),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
