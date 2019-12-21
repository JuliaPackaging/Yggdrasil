# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "capnproto"
version = v"0.7.0"

# Collection of sources required to build capnproto
sources = [
    "https://capnproto.org/capnproto-c++-$(version).tar.gz" =>
    "c9a4c0bd88123064d483ab46ecee777f14d933359e23bff6fb4f4dbd28b4cd41",
    "./bundled"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/capnproto-*/
atomic_patch -p2 ${WORKSPACE}/srcdir/patches/aligned-alloc.patch
./configure --prefix=$prefix --host=$target
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcapnp", :libcapnp),
    ExecutableProduct("capnp", :capnp)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
              preferred_gcc_version=v"5")
