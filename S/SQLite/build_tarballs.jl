# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "SQLite"
version = v"3.30.1"

# Collection of sources required to build SQLite
sources = [
    "https://www.sqlite.org/2019/sqlite-autoconf-3300100.tar.gz" =>
    "8c5a50db089bd2a1b08dbc5b00d2027602ca7ff238ba7658fabca454d4298e60",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sqlite-autoconf-*/
./configure --prefix=$prefix --host=$target
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libsqlite3", :libsqlite)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
