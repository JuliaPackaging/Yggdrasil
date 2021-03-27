# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "cmocka"
version = v"1.1.5"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://cmocka.org/files/$(version.major).$(version.minor)/cmocka-$(version).tar.xz", "f0ccd8242d55e2fd74b16ba518359151f6f8383ff8aef4976e48393f77bba8b6"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cmocka-*/
atomic_patch -p1 $WORKSPACE/srcdir/patches/wordsize.patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/musl_uintptr.patch
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = LibraryProduct[
    # TBD
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
