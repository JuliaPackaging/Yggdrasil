# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libgpg_error"
version = v"1.36"

# Collection of sources required to build Libgpg-Error
sources = [
    "https://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-$(version.major).$(version.minor).tar.bz2" =>
    "babd98437208c163175c29453f8681094bcaf92968a15cafb1a276076b33c97c",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libgpg-error-*/

for p in ${WORKSPACE}/srcdir/patches/*; do
    atomic_patch -p1 "${p}"
done

# "Generate" new arch platform definitions because they're actually really simple. :P
cp -iv src/syscfg/lock-obj-pub.i686-unknown-linux-gnu.h src/syscfg/lock-obj-pub.i686-unknown-linux-musl.h
cp -iv src/syscfg/lock-obj-pub.aarch64-unknown-linux-gnu.h src/syscfg/lock-obj-pub.aarch64-unknown-linux-musl.h
cp -iv src/syscfg/lock-obj-pub.arm-unknown-linux-gnueabi.h src/syscfg/lock-obj-pub.arm-unknown-linux-musleabihf.h
cp -iv src/syscfg/lock-obj-pub.x86_64-unknown-linux-gnu.h src/syscfg/lock-obj-pub.freebsd11.1.h

# Use libgpg-specific mapping for triplets
TARGET="${target}"
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    TARGET=x86_64-apple-darwin
fi

# We need `msgformat`
apk add gettext

./configure --prefix=${prefix} --host=${TARGET} --build=${MACHTYPE}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  We are manually disabling
# many platforms that do not seem to work.
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libgpg-error", "libgpg-error6"], :libgpg_error),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
