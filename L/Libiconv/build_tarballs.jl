using BinaryBuilder

# Collection of sources required to build Gettext
name = "Libiconv"
version = v"1.15"
sources = [
    "https://ftp.gnu.org/pub/gnu/libiconv/libiconv-$(version.major).$(version.minor).tar.gz" =>
    "ccf536620a45458d26ba83887a983b96827001e92a13847b45e4925cc8913178",
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
products(prefix) = [
    LibraryProduct(prefix, "libiconv", :libiconv)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

