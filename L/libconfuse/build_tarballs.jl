# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libconfuse"
version = v"3.2.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/martinh/libconfuse/releases/download/v3.2.2/confuse-3.2.2.tar.gz",
                  "71316b55592f8d0c98924242c98dbfa6252153a8b6e7d89e57fe6923934d77d0"),

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/confuse-*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
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
    FreeBSD(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libconfuse", :libconfuse)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

