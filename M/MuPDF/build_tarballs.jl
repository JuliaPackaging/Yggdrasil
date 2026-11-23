using BinaryBuilder, Pkg

name = "MuPDF"

version = v"1.28.6"

# The GitSource's third-party libraries are submodules of Artifex's own organization; the source
# tarball carries them, and they are what gets built (like HAVE_LIBARCHIVE=no, which keeps out the
# one that would otherwise come from the system).
sources = [
    ArchiveSource("https://mupdf.com/downloads/archive/mupdf-$(version)-source.tar.gz",
                  "dc85000640a45d90ca9b77b061f6ca67cce0c4d4fbecf8819647baf573eef101"),
    DirectorySource(joinpath(@__DIR__, "bundled")),
]

script = raw"""
cd ${WORKSPACE}/srcdir/mupdf*

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/getentropy.patch
make -j${nproc} build=release HAVE_X11=no HAVE_GLUT=no HAVE_LIBCRYPTO=no HAVE_LIBARCHIVE=no
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
# The IJG terms are the README's letters section, as e.g. Yggdrasil's JpegTurbo3 recipe takes them.
install -Dvm 644 thirdparty/libjpeg/README ${prefix}/share/licenses/MuPDF/libjpeg-README
install_license thirdparty/leptonica/leptonica-license.txt
install_license thirdparty/mujs/COPYING
install_license thirdparty/openjpeg/LICENSE
install_license thirdparty/tesseract/LICENSE
install_license thirdparty/zint/LICENSE
install_license thirdparty/zlib/LICENSE
install_license thirdparty/zxing-cpp/LICENSE
"""

# Windows is left out for now: with MinGW's headers, the SSE4.1 intrinsics that deskew.c and skew.c
# use once ARCH_HAS_SSE is set are not inlinable at the flags the build passes. Whoever returns to it
# needs a Windows cross toolchain to see the flags that compile those files.
platforms = filter!(p -> !Sys.iswindows(p), supported_platforms())

products = [
    ExecutableProduct("mutool", :mutool),
]

dependencies = Dependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"6")
