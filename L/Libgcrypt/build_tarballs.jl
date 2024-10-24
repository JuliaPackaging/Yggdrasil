# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libgcrypt"
version = v"1.11.0"

# Collection of sources required to build libgcrypt
sources = [
    ArchiveSource("https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-$(version).tar.bz2",
                  "09120c9867ce7f2081d6aaa1775386b98c2f2f246135761aae47d81f58685b9c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libgcrypt-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --disable-padlock-support \
    --enable-random=linux \ # no getentropy with our old glibc
    --disable-asm
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  We are manually disabling
# many platforms that do not seem to work.
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libgcrypt", :libgcrypt),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Libgpg_error_jll"; compat="1.49.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
