# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "GraphicsMagick"
version = v"1.3.45"

# Collection of sources required to build GraphicsMagick
sources = [
    ArchiveSource("https://sourceforge.net/projects/graphicsmagick/files/graphicsmagick/$(version)/GraphicsMagick-$(version).tar.xz",
                  "dcea5167414f7c805557de2d7a47a9b3147bcbf617b91f5f0f4afe5e6543026b"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/GraphicsMagick*

# Don't use `clock_realtime` if it isn't available
atomic_patch -p1 ../patches/check-have-clock-realtime.patch

# While all libraries are available, only the last set of header files
# (here depth=8) remain available.
for depth in 32 16 8; do
    mkdir build-${depth}
    pushd build-${depth}
    # `configure` runs Ghostscript binaries -- this does not work when cross-compiling
    ../configure \
        --build=${MACHTYPE} \
        --host=${target} \
        --prefix=${prefix} \
        --disable-dependency-tracking \
        --disable-installed \
        --disable-static \
        --docdir=/tmp \
        --enable-openmp \
        --enable-quantum-library-names \
        --enable-shared \
        --with-quantum-depth=${depth} \
        --without-gs \
        --without-frozenpaths \
        --without-perl \
        --without-x
    make -j${nproc}
    make install
    popd
done
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libGraphicsMagick-Q8", :libGraphicsMagick_Q8),
    LibraryProduct("libGraphicsMagick++-Q8", :libGraphicsMagickxx_Q8),
    LibraryProduct("libGraphicsMagickWand-Q8", :libGraphicsMagickWand_Q8),
    LibraryProduct("libGraphicsMagick-Q16", :libGraphicsMagick_Q16),
    LibraryProduct("libGraphicsMagick++-Q16", :libGraphicsMagickxx_Q16),
    LibraryProduct("libGraphicsMagickWand-Q16", :libGraphicsMagickWand_Q16),
    LibraryProduct("libGraphicsMagick-Q32", :libGraphicsMagick_Q32),
    LibraryProduct("libGraphicsMagick++-Q32", :libGraphicsMagickxx_Q32),
    LibraryProduct("libGraphicsMagickWand-Q32", :libGraphicsMagickWand_Q32),
    ExecutableProduct("gm", :gm),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM
    # as compiler (BSD systems), and libgomp from
    # `CompilerSupportLibraries_jll` everywhere else.
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.isbsd, platforms)),
    Dependency("LLVMOpenMP_jll"; platforms=filter(Sys.isbsd, platforms)),
    Dependency("Bzip2_jll"; compat="1.0.8"),
    Dependency("FreeType2_jll"; compat="2.10.4"),
    # Dependency("Ghostscript_jll"),
    Dependency("Graphviz_jll"),
    Dependency("JasPer_jll"),
    Dependency("JpegTurbo_jll"),
    Dependency("Libtiff_jll"; compat="4.5.1"),
    Dependency("XML2_jll"),
    Dependency("XZ_jll"),
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"),
    Dependency("gperftools_jll"),
    Dependency("libpng_jll"),
    Dependency("libwebp_jll"; compat="1.2.4"),
    # TODO:
    # - ralcgm <http://www.agocg.ac.uk/train/cgm/ralcgm.htm>
    # - cdraw <https://www.dechifro.org/dcraw/>
    # - fig2dev <http://mcj.sourceforge.net/>
    # - hp2xx <http://www.gnu.org/software/hp2xx/hp2xx.html>
    # - lcms <http://www.littlecms.com/>
    # - html2pl <https://sourceforge.net/projects/html2ps/>
    # - JBIG-Kit <http://www.cl.cam.ac.uk/~mgk25/jbigkit/>
    # - MPEG <mpeg2vidcodec_v12.tar.gz>
    # - TIFF <https://libtiff.gitlab.io/libtiff/>
    # - TRIO <http://sourceforge.net/projects/ctrio/>
    # - umum <https://github.com/omniti-labs/portableumem>
    # - libwmf <http://sourceforge.net/projects/wvware/>
    # - heif <https://github.com/strukturag/libheif>
    # - libde265 <https://github.com/strukturag/libde265>
    # - JPEG XL (JXL) <https://github.com/libjxl/libjxl>
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", clang_use_lld=false)
