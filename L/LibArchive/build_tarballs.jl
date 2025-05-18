# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LibArchive"
version = v"3.7.9"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.libarchive.org/downloads/libarchive-$(version).tar.xz",
                  "ed8b5732e4cd6e30fae909fb945cad8ff9cb7be5c6cdaa3944ec96e4a200c04c"),
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
    Dependency("acl_jll"; platforms=filter(Sys.islinux, platforms)),
    Dependency("Attr_jll"; platforms=filter(Sys.islinux, platforms)),
    Dependency("Bzip2_jll"; compat="1.0.9"),
    Dependency("Expat_jll"; compat="2.6.5"),
    Dependency("Libiconv_jll"),
    Dependency("Lz4_jll"),
    Dependency("OpenSSL_jll"; compat="3.0.16"),
    Dependency("XZ_jll"),
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
