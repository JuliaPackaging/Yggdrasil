# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "GraphicsMagick"
version = v"1.3.40"

# Collection of sources required to build imagemagick
sources = [
    ArchiveSource("https://sourceforge.net/projects/graphicsmagick/files/graphicsmagick/$(version)/GraphicsMagick-$(version).tar.xz",
                  "97dc1a9d4e89c77b25a3b24505e7ff1653b88f9bfe31f189ce10804b8efa7746"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/GraphicsMagick*
# TODO:
# - jpeg support does not build, we are getting confused by some jpeg library that is pulled in transitively.
./configure \
    --build=${MACHTYPE} \
    --host=${target} \
    --prefix=${prefix} \
    --disable-dependency-tracking \
    --disable-installed\
    --disable-jpeg \
    --disable-static \
    --docdir=/tmp \
    --enable-openmp \
    --enable-quantum-library-names \
    --enable-shared \
    --with-gs \
    --without-frozenpaths \
    --without-perl \
    --without-x
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libGraphicsMagick", :libGraphicsMagick),
    LibraryProduct("libGraphicsMagick++", :libGraphicsMagickxx),
    LibraryProduct("libGraphicsMagickWand", :libGraphicsMagickWand),
    ExecutableProduct("gm", :gm),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM
    # as compiler (BSD systems), and libgomp from
    # `CompilerSupportLibraries_jll` everywhere else.
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.isbsd, platforms)),
    Dependency("LLVMOpenMP_jll"; platforms=filter(Sys.isbsd, platforms)),
    Dependency("Bzip2_jll"),
    Dependency("FreeType2_jll"),
    Dependency("Ghostscript_jll"),
    Dependency("Graphviz_jll"),
    Dependency("JasPer_jll"),
    # Dependency("JpegTurbo_jll"),   # error: ‘struct jpeg_decompress_struct’ has no member named ‘process’
    # Dependency("OpenJpeg_jll"),   # error: ‘struct jpeg_decompress_struct’ has no member named ‘process’
    Dependency("Libtiff_jll"),
    Dependency("XML2_jll"),
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"),
    Dependency("gperftools_jll"),
    Dependency("libpng_jll"),
    Dependency("libwebp_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
