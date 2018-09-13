using BinaryBuilder

name = "SuperBinutils"
version = v"2.29.1"

# Collection of sources required to build Ogg
sources = [
    "https://ftp.gnu.org/gnu/binutils/binutils-$(version).tar.xz" =>
    "e7010a46969f9d3e53b650a518663f98a5dde3c3ae21b7d71e5e6803bc36b577",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/binutils-*/

# Targets we build our super binutils for, which is all of them
# EXCEPT darwin because we can't build `ld` for that platform.
# It's infuriating, but that's why we have to build CCtools.  :(
super_targets=x86_64-linux-gnu,i686-linux-gnu,aarch64-linux-gnu,arm-linux-gnueabihf,powerpc64le-linux-gnu,x86_64-w64-mingw32,i686-w64-mingw32,x86_64-unknown-freebsd

# So what we'll do is build everything EXCEPT `ld` for everything,
# then build `ld` for everything EXCEPT darwin.
mkdir $WORKSPACE/srcdir/binutils_build
cd $WORKSPACE/srcdir/binutils_build
$WORKSPACE/srcdir/binutils-*/configure --prefix=${prefix} \
    --enable-targets=${super_targets},x86_64-apple-darwin \
    --enable-multilib \
    --disable-werror \
    --disable-ld

make -j${nproc}
make install

# Clean out and then reconfigure and build for only `ld`
rm -rf *
$WORKSPACE/srcdir/binutils-*/configure --prefix=${prefix} \
    --enable-targets=${super_targets} \
    --enable-multilib \
    --disable-werror \
    --enable-ld \

make -j${nproc} all-ld 
make install-ld
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, :glibc)
]

# The products that we will ensure are always built
products = prefix -> [
    ExecutableProduct(prefix, "as", :as),
    ExecutableProduct(prefix, "nm", :nm),
    ExecutableProduct(prefix, "ld", :ld),
    ExecutableProduct(prefix, "strip", :strip),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
