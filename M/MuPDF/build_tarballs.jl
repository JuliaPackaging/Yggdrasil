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
# The bundled projects' license files share names (COPYING, LICENSE), so each is installed under its
# project's name rather than over the previous one. IJG's terms are the libjpeg README's letters
# section, as other recipes here take them.
for f in brotli/LICENSE cmark-gfm/COPYING curl/COPYING extract/COPYING freeglut/COPYING \
         freetype/LICENSE.TXT gumbo-parser/COPYING harfbuzz/COPYING jbig2dec/COPYING lcms2/LICENSE \
         leptonica/leptonica-license.txt libjpeg/README mujs/COPYING openjpeg/LICENSE \
         tesseract/LICENSE zint/LICENSE zlib/LICENSE zxing-cpp/LICENSE; do
    install -Dvm 644 thirdparty/${f} ${prefix}/share/licenses/MuPDF/${f%%/*}-${f##*/}
done
"""

platforms = supported_platforms()

products = [
    ExecutableProduct("mutool", :mutool),
]

dependencies = Dependency[]

# The bundled cmark-gfm uses C99 for-loop declarations, which the default GCC 4.8 rejects in its gnu90
# mode ("'for' loop initial declarations are only allowed in C99 mode"); GCC 5 defaults to gnu11.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
