# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "libass"
version = v"0.17.5"

# Collection of sources required to build libass
sources = [
    ArchiveSource("https://github.com/libass/libass/releases/download/$(version)/libass-$(version).tar.xz",
                  "2dca25c0e0c837ddf00b52011b3f82cac1e4ddd3ad018227806b0c2288864acc"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libass-*
apk add nasm
# On FreeBSD, HarfBuzz_jll ships its pkg-config files in libdata/pkgconfig
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH:+${PKG_CONFIG_PATH}:}${prefix}/libdata/pkgconfig"
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
    Dependency("FreeType2_jll"; compat="2.13.4"),
    Dependency("FriBidi_jll"),
    Dependency("HarfBuzz_jll"; compat="100.14003"),
    Dependency("Bzip2_jll"; compat="1.0.9"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
