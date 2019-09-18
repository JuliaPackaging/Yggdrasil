# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libfdk"
version = v"0.1.6"

# Collection of sources required to build libfdk
sources = [
    "https://downloads.sourceforge.net/opencore-amr/fdk-aac-0.1.6.tar.gz" =>
    "aab61b42ac6b5953e94924c73c194f08a86172d63d39c5717f526ca016bed3ad",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd fdk-aac-0.1.6/
./configure --prefix=$prefix --host=$target
make -j${ncore}
make install
exit

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, :glibc),
    Linux(:x86_64, :glibc),
    Linux(:aarch64, :glibc),
    Linux(:armv7l, :glibc, :eabihf),
    Linux(:powerpc64le, :glibc),
    Linux(:i686, :musl),
    Linux(:x86_64, :musl),
    Linux(:aarch64, :musl),
    Linux(:armv7l, :musl, :eabihf),
    MacOS(:x86_64),
    FreeBSD(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libfdk-aac", :libfdk)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

