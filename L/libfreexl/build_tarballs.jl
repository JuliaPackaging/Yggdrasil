# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libfreexl"
version = v"2.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.gaia-gis.it/gaia-sins/freexl-sources/freexl-$(version).tar.gz",
                  "176705f1de58ab7c1eebbf5c6de46ab76fcd8b856508dbd28f5648f7c6e1a7f0"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/freexl-*

update_configure_scripts

./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-xmldocs

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libfreexl", :libfreexl),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Libiconv_jll"; platforms=filter(Sys.iswindows, platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
