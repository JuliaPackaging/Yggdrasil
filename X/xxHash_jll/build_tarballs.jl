# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "xxHash_jll"
version = v"0.7.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Cyan4973/xxHash.git", "173e50be0509c6fb6c1bb74d95049ef61d7fdced")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd xxHash/
CPPFLAGS=-DXXH_INLINE_ALL make
if [ ! -d $libdir ]; then
  mkdir -p $libdir;
fi
cp libxxhash.$dlext $libdir/libxxhash.$dlext
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
    LibraryProduct("libxxhash", :libxxhash_074)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
