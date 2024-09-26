# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libgcrypt"
version = v"1.10.3"

# Collection of sources required to build libgcrypt
sources = [
    ArchiveSource("https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-$(version).tar.bz2",
                  "8b0870897ac5ac67ded568dcfadf45969cfa8a6beb0fd60af2a9eadc2a3272aa"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libgcrypt-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --disable-padlock-support \
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
    Dependency("Libgpg_error_jll", v"1.42.0"; compat="1.42.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
