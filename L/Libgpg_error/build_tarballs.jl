# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg.BinaryPlatforms

name = "Libgpg_error"
version = v"1.36"

# Collection of sources required to build Libgpg-Error
sources = [
    "https://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-$(version.major).$(version.minor).tar.bz2" =>
    "babd98437208c163175c29453f8681094bcaf92968a15cafb1a276076b33c97c",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libgpg-error-*/

# Use libgpg-specific mapping for triplets
TARGET="${target}"
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    TARGET=x86_64-apple-darwin
elif [[ "${target}" == x86_64-*-freebsd* ]]; then
    TARGET=x86_64-unknown-kfreebsd-gnu
fi

./configure --prefix=${prefix} --host=${TARGET} --build=${MACHTYPE}
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
    # Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    # Linux(:aarch64, libc=:musl),
    # Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    MacOS(:x86_64),
    FreeBSD(:x86_64),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libgpg-error", :libgpg_error),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
