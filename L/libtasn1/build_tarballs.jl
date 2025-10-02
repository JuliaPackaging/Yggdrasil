# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libtasn1"
version = v"4.19.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/libtasn1/libtasn1-$(version).tar.gz",
                  "1613f0ac1cf484d6ec0ce3b8c06d56263cc7242f1c23b30d82d23de345a63f7a")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libtasn1-*
install_license COPYING
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libtasn1", :libtasn1),
    ExecutableProduct("asn1Decoding", :asn1Decoding),
    ExecutableProduct("asn1Parser", :asn1Parser),
    ExecutableProduct("asn1Coding", :asn1Coding)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
