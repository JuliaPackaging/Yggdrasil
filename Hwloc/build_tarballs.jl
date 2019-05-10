# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "hwloc"
version = v"2.0.3"

# Collection of sources required to build hwloc
sources = [
    "https://download.open-mpi.org/release/hwloc/v2.0/hwloc-2.0.3.tar.bz2" =>
    "e393aaf39e576b329a2bff3096d9618d4e39f416874390b58e6573349554c725",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd hwloc-2.0.3/
./configure --prefix=$prefix --host=$target
make
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    MacOS(:x86_64),
    FreeBSD(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libhwloc", :libhwloc)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

