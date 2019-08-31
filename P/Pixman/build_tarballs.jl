using BinaryBuilder, Pkg.BinaryPlatforms

# Collection of sources required to build Pixman
name = "Pixman"
version = v"0.36.0"
sources = [
    "https://www.cairographics.org/releases/pixman-$(version).tar.gz" =>
    "1ca19c8d4d37682adfbc42741d24977903fec1169b4153ec05bb690d4acf9fae",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pixman-*/

# Apply patch for compilation with clang
#patch < $WORKSPACE/srcdir/patches/clang.patch

# Apply patch for arm on musl
#patch -p1 < $WORKSPACE/srcdir/patches/arm_musl.patch

./configure --prefix=$prefix --host=$target
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libpixman", :libpixman)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
product_hashes = build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
