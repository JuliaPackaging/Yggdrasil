using BinaryBuilder

name = "LibUV"
version = v"2"

# Collection of sources required to build libuv
sources = [
    GitSource("https://github.com/JuliaLang/libuv.git",
              "c6869fba163a1e04af64ede438a8fd0191e75e9e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libuv/

# Touch some files so that the build system doesn't attempt to re-run `autoconf`:
touch -c aclocal.m4
touch -c Makefile.in
touch -c configure

# `--with-pic` isn't enough; we really really need -fPIC and -DPIC everywhere...
# everywhere, especially on FreeBSD. In the end, isn't FreeBSD all that matters?
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-pic CFLAGS="${CFLAGS} -DPIC -fPIC" CXXFLAGS="${CXXFLAGS} -DPIC -fPIC"
make -j${nproc} V=1
make install
"""

# We enable experimental platforms as this is a core Julia dependency
platforms = supported_platforms(;experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libuv", :libuv),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Note: we explicitly lie about this because we don't have the new
# versioning APIs worked out in BB yet.
version = v"2.0.1"
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

