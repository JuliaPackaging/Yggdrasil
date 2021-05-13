# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "libass"
version = v"0.14.0"

# Collection of sources required to build libass
sources = [
    ArchiveSource("https://github.com/libass/libass/releases/download/$(version)/libass-$(version).tar.xz",
                  "881f2382af48aead75b7a0e02e65d88c5ebd369fe46bc77d9270a94aa8fd38a2"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libass-*
apk add nasm
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-require-system-font-provider --disable-static
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libass", :libass),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("FreeType2_jll"),
    Dependency("FriBidi_jll"),
    # Future versions of bzip2 should allow a more relaxed compat because the
    # soname of the macOS library shouldn't change at every patch release.
    Dependency("Bzip2_jll", v"1.0.6"; compat="=1.0.6"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
