using BinaryBuilder

name = "Libffi"
version = v"3.3"

# Collection of sources required to build libffi
sources = [
    "https://github.com/libffi/libffi/releases/download/v3.3/libffi-3.3.tar.gz" =>
    "72fba7922703ddfa7a028d513ac15a85c8d54c8d67f55fa5a4802885dc652056",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libffi-*/
update_configure_scripts
autoreconf -f -i
./configure --prefix=$prefix --host=$target --disable-static --enable-shared
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libffi", :libffi)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

