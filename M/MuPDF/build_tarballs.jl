using BinaryBuilder, Pkg

name = "MuPDF"

version = v"1.28.6"

# Upstream's git repository keeps the third-party libraries it bundles (zlib, MuJS, brotli, lcms2,
# freetype and the rest) as submodules under Artifex's own organization; its source tarball carries
# them. They are all built in, as upstream does, and HAVE_LIBARCHIVE=no keeps out the one library it
# would otherwise take from the system.
sources = [
    ArchiveSource("https://mupdf.com/downloads/archive/mupdf-$(version)-source.tar.gz",
                  "dc85000640a45d90ca9b77b061f6ca67cce0c4d4fbecf8819647baf573eef101"),
    DirectorySource(joinpath(@__DIR__, "bundled")),
]

script = raw"""
cd ${WORKSPACE}/srcdir/mupdf*

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/getentropy.patch

# MinGW's MSVC-compatible _M_AMD64 is the one thing that makes MuPDF's ARCH_HAS_SSE come out set, and
# the code behind it needs SSE4.1 flags this build does not pass. Every other target, Linux, macOS and
# the BSDs included, already takes the portable path, so Windows is put on it too rather than have the
# binary require a CPU feature.
if [[ "${target}" == *-mingw* ]]; then
    XCFLAGS="-DARCH_HAS_SSE=0"
fi

make -j${nproc} build=release HAVE_X11=no HAVE_GLUT=no HAVE_LIBCRYPTO=no HAVE_LIBARCHIVE=no XCFLAGS="${XCFLAGS:-}"
install -Dvm 755 build/release/mutool ${bindir}/mutool${exeext}

install_license COPYING
install_license thirdparty/brotli/LICENSE
install_license thirdparty/cmark-gfm/COPYING
install_license thirdparty/curl/COPYING
install_license thirdparty/extract/COPYING
install_license thirdparty/freeglut/COPYING
install_license thirdparty/freetype/LICENSE.TXT
install_license thirdparty/gumbo-parser/COPYING
install_license thirdparty/harfbuzz/COPYING
install_license thirdparty/jbig2dec/COPYING
install_license thirdparty/lcms2/LICENSE
# IJG's terms are the README's letters section, as other recipes here take them.
install -Dvm 644 thirdparty/libjpeg/README ${prefix}/share/licenses/MuPDF/libjpeg-README
install_license thirdparty/leptonica/leptonica-license.txt
install_license thirdparty/mujs/COPYING
install_license thirdparty/openjpeg/LICENSE
install_license thirdparty/tesseract/LICENSE
install_license thirdparty/zint/LICENSE
install_license thirdparty/zlib/LICENSE
install_license thirdparty/zxing-cpp/LICENSE
"""

platforms = supported_platforms()

products = [
    ExecutableProduct("mutool", :mutool),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
