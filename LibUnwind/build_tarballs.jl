using BinaryBuilder

name = "LibUnwind"
version = v"1.3.1"

# Collection of sources required to build libffi
sources = [
    "https://github.com/libunwind/libunwind/releases/download/v$(version)/libunwind-$(version).tar.gz" =>
    "43997a3939b6ccdf2f669b50fdb8a4d3205374728c2923ddc2354c65260214f8",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libunwind*/

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/libunwind-prefer-extbl.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/libunwind-static-arm.patch

./configure --prefix=$prefix --host=$target CFLAGS="${CFLAGS} -fPIC"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  libunwind is only used
# on Linux or FreeBSD (e.g. ELF systems), and doesn't work on Musl yet
platforms = [p for p in supported_platforms() if (isa(p, Linux) && libc(p) == :glibc) || isa(p, FreeBSD)]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libunwind", :libunwind)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

