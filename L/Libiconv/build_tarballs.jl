using BinaryBuilder

# Collection of sources required to build Libiconv
name = "Libiconv"
version = v"1.16"
sources = [
    "https://ftp.gnu.org/pub/gnu/libiconv/libiconv-$(version.major).$(version.minor).tar.gz" =>
    "e6a1b1b589654277ee790cce3734f07876ac4ccfaecbee8afa0b649cf529cc04",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libiconv-*/
./configure --prefix=$prefix --host=$target
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libiconv", :libiconv)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

