# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MuPDF"
version = v"1.28.6"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://mupdf.com/downloads/archive/mupdf-$(version)-source.tar.gz",
                  "dc85000640a45d90ca9b77b061f6ca67cce0c4d4fbecf8819647baf573eef101"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/mupdf-*-source
# The C libraries Linux builds target may have no getentropy().
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/getentropy.patch

# mutool alone, from the third-party libraries MuPDF bundles: it carries its own forks of some
# (lcms2, mujs), and builds the rest with the configuration it expects. No viewers, OCR or barcodes.
args=(
    build=release verbose=yes
    CC=cc CXX=c++ AR=ar LD=ld RANLIB=ranlib
    USE_SYSTEM_LIBS=no HAVE_GLUT=no HAVE_X11=no HAVE_LIBCRYPTO=no HAVE_CURL=no
    tesseract=no barcode=no
)
if [[ "${target}" == *-apple-* ]]; then
    # Darwin's rules call the compilers through xcrun; the arguments above override them.
    args+=(OS=Darwin)
elif [[ "${target}" == *-linux-* ]]; then
    # Linux's rules embed the fonts with `ld -r -b binary`.
    args+=(OS=Linux)
else
    # Elsewhere the fonts are embedded as C sources.
    args+=(OS=Other HAVE_OBJCOPY=no)
fi
if [[ "${target}" == *-mingw* ]]; then
    # MuPDF takes SSE4.1 for granted where the compiler defines MSVC's architecture macros, as
    # MinGW's does, without the flags that enable it.
    args+=(XCFLAGS=-DARCH_HAS_SSE=0)
fi

make -j${nproc} "${args[@]}" tools
# The Makefile names it without `.exe`, which some MinGW linkers add and others don't.
exe=build/release/mutool
[[ -f "${exe}${exeext}" ]] && exe="${exe}${exeext}"
install -Dvm 755 "${exe}" "${bindir}/mutool${exeext}"
install_license COPYING
# The notices of the bundled libraries mutool links, and of the fonts it embeds.
for f in thirdparty/{brotli/LICENSE,cmark-gfm/COPYING,extract/COPYING,freetype/LICENSE.TXT,freetype/docs/FTL.TXT} \
         thirdparty/{gumbo-parser/COPYING,harfbuzz/COPYING,jbig2dec/LICENSE,lcms2/LICENSE,libjpeg/README} \
         thirdparty/{mujs/COPYING,openjpeg/LICENSE,zlib/LICENSE} \
         resources/fonts/{droid/NOTICE,han/LICENSE.txt,noto/COPYING,sil/OFL.txt,urw/OFL.txt}; do
    n="${f#thirdparty/}"; n="${n#resources/fonts/}"
    install -Dvm 644 "${f}" "${prefix}/share/licenses/${SRC_NAME}/${n//\//-}"
done
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("mutool", :mutool),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
# GCC 5 is the first to compile C as C99 or later by default, which the bundled libraries assume.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
