# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "P4est"
version = v"2.2.0"

# Collection of sources required to complete build
sources = [
    FileSource("https://p4est.github.io/release/p4est-2.2.tar.gz", "1549cbeba29bee2c35e7cc50a90a04961da5f23b6eada9c8047f511b90a8e438"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd p4est-2.2/
if [[ "${target}" == *-freebsd* ]]; then
  export LIBS="-lm"
fi
CFLAGS="-I${prefix}/include" LDFLAGS="-L${prefix}/lib" ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --without-blas
make -j${nproc}
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
    FreeBSD(:x86_64)
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libp4est", :libp4est),
    LibraryProduct("libsc", :libsc)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
