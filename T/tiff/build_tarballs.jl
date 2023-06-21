# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "tiff"
version = v"4.5.1"

# Collection of sources required to build tiff
sources = [
    ArchiveSource("https://download.osgeo.org/libtiff/tiff-$(version).tar.xz",
                  "3c080867114c26edab3129644a63b708028a90514b7fe3126e38e11d24f9f88a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tiff*
./configure --build=${MACHTYPE} --host=${target} --prefix=${prefix} --docdir=/tmp
make -j$(nproc)
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libtiff", :libtiff), 
    LibraryProduct("libtiffxx", :libtiffxx), 
    ExecutableProduct("fax2ps", :faxps),
    ExecutableProduct("fax2tiff", :fax2tiff),
    ExecutableProduct("pal2rgb", :pal2rgb),
    ExecutableProduct("ppm2tiff", :ppm2tiff),
    ExecutableProduct("raw2tiff", :raw2tiff),
    ExecutableProduct("tiff2bw", :tiff2bw),
    ExecutableProduct("tiff2pdf", :tiff2pdf),
    ExecutableProduct("tiff2ps", :tiff2ps),
    ExecutableProduct("tiff2rgba", :tiff2rgba),
    ExecutableProduct("tiffcmp", :tiffcmp),
    ExecutableProduct("tiffcp", :tiffcp),
    ExecutableProduct("tiffcrop", :tiffcrop),
    ExecutableProduct("tiffdither", :tiffdither),
    ExecutableProduct("tiffdump", :tiffdump),
    ExecutableProduct("tiffinfo", :tiffinfo),
    ExecutableProduct("tiffmedian", :tiffmedian),
    ExecutableProduct("tiffset", :tiffset),
    ExecutableProduct("tiffsplit", :tiffsplit),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("JpegTurbo_jll"),
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"),
    Dependency("libwebp_jll"),
    # TODO:
    # - jbig
    # - jpeg12
    # - lerc
    # - libdeflate
    # - lzma
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
