using BinaryBuilder

name = "LibUV"
version = v"2+1.29.1-julia"

# Collection of sources required to build libffi
sources = [
    "https://github.com/JuliaLang/libuv.git" =>
    "35b1504507a7a4168caae3d78db54d1121b121e1",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libuv/

# Touch some files so that the build system doesn't try to re-run `acreconf`:
touch -c aclocal.m4
touch -c Makefile.in
touch -c configure

# `--with-pic` isn't enough; we really really need -fPIC and -DPIC everywhere...
# everywhere, especially on FreeBSD
./configure --prefix=$prefix --host=$target --with-pic CFLAGS="${CFLAGS} -DPIC -fPIC" CXXFLAGS="${CXXFLAGS} -DPIC -fPIC"
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
