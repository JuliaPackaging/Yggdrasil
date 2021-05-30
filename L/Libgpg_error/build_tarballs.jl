# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libgpg_error"
version = v"1.42"

# Collection of sources required to build Libgpg-Error
sources = [
    ArchiveSource("https://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-$(version.major).$(version.minor).tar.bz2",
                  "fc07e70f6c615f8c4f590a8e37a9b8dd2e2ca1e9408f8e60459c67452b925e23"),
    DirectorySource("./bundled"),
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
if [[ "${target}" == *-apple-darwin* ]]; then
    TARGET="$(echo "${target}" | cut -d- -f1)-apple-darwin"
fi

# We patched `configure.ac` to force always using lock files in `src/syscfg`
# to generate `src/gpg-error.h`, so we need to update `configure`
autoreconf -fiv

./configure --prefix=${prefix} --host=${TARGET} --build=${MACHTYPE}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  We are manually disabling
# many platforms that do not seem to work.
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libgpg-error", "libgpg-error6"], :libgpg_error),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # We need `msgformat`
    HostBuildDependency("Gettext_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
