# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Tar"
version = v"1.32"

# Collection of sources required to build tar
sources = [
    "https://ftp.gnu.org/gnu/tar/tar-$(version.major).$(version.minor).tar.xz" =>
    "d0d3ae07f103323be809bc3eac0dcc386d52c5262499fe05511ac4788af1fdd8",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tar-*/
export FORCE_UNSAFE_CONFIGURE=1
./configure --prefix=${prefix} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  We are manually disabling
# many platforms that do not seem to work.
platforms = [p for p in supported_platforms() if !(p isa Windows)]

# The products that we will ensure are always built
products = [
    ExecutableProduct("tar", :tar),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Attr_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
