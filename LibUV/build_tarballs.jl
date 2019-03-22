using BinaryBuilder

name = "LibUV"
version = v"1.24.0"

# Collection of sources required to build libffi
sources = [
    "https://github.com/JuliaLang/libuv.git" =>
    "2348256acf5759a544e5ca7935f638d2bc091d60",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libuv/

# Touch some files so that the build system doesn't try to re-run `acreconf`:
touch -c aclocal.m4
touch -c Makefile.in
touch -c configure

./configure --prefix=$prefix --host=$target --with-pic
make -j${nproc} V=1
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libuv", :libuv)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

