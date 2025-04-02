# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libgcrypt"
version = v"1.11.0"
# We bumped the version because we updated the dependencies to build for riscv64
ygg_version = v"1.11.1"

# Collection of sources required to build libgcrypt
sources = [
    ArchiveSource("https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-$(version).tar.bz2",
                  "09120c9867ce7f2081d6aaa1775386b98c2f2f246135761aae47d81f58685b9c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libgcrypt-*

BUILD_FLAGS=(--disable-padlock-support --disable-asm)

if [[ "${target}" == *linux* ]]; then
    # on our old glibc, we don't have getentropy
    BUILD_FLAGS+=(--enable-random=linux)
fi

if [[ "${target}" == *mingw* ]]; then
    # Work around JuliaPackaging/Yggdrasil#9687
    sed -i 's/CLOCK_REALTIME/0/g' random/jitterentropy-base-user.h
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} "${BUILD_FLAGS[@]}"

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
    Dependency("Libgpg_error_jll"; compat="1.51.1"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
