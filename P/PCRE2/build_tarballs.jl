# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PCRE2"
version = v"10.34.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.pcre.org/pub/pcre/pcre2-10.34.tar.gz", "da6aba7ba2509e918e41f4f744a59fa41a2425c59a298a232e7fe85691e00379")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd pcre2-10.34
./configure --prefix=$prefix --host=$target --enable-jit --enable-pcre2-16 --enable-pcre2-32
make
make install
exit
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
    LibraryProduct("libpcre2", :libpcre2_32),
    LibraryProduct("libpcre2", :libpcre2_16),
    LibraryProduct("libpcre2", :libpcre2_8)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
