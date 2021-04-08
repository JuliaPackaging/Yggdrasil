# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LibArchive"
version = v"3.5.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.libarchive.org/downloads/libarchive-$(version).tar.xz", "0e17d3a8d0b206018693b27f08029b598f6ef03600c2b5d10c94ce58692e299b")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libarchive-*/
export CPPFLAGS="-I${includedir}"
./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --with-expat \
    --with-openssl \
    --without-xml2 \
    --without-nettle \
    --disable-static
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libarchive", :libarchive),
    ExecutableProduct("bsdcpio", :bsdcpio),
    ExecutableProduct("bsdtar", :bsdtar),
    ExecutableProduct("bsdcat", :bsdcat)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("acl_jll"),
    Dependency("Attr_jll"),
    Dependency("Bzip2_jll"),
    Dependency("Expat_jll"),
    Dependency("Libiconv_jll"),
    Dependency("Lz4_jll"),
    Dependency("OpenSSL_jll"),
    Dependency("XZ_jll"),
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
