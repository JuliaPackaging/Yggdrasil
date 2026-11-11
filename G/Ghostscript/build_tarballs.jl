# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Ghostscript"
version_string = "10.08.0"
version = VersionNumber(version_string)

# Collection of sources required to build
sources = [
    ArchiveSource(
        "https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs$(replace(version_string, "." => ""))/ghostscript-$(version_string).tar.gz", # URL
        "caf199e3f233f1290b27d0972d636f66c303355f2353309b7bfddf1edda06b3d" # SHA256 hash
    ),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ghostscript*

if [[ "${target}" == *-mingw* ]]; then
    atomic_patch -p1 ../patches/001-mingw-build.patch
    atomic_patch -p1 ../patches/003-libspectre.patch
    export MINGW_BUILD=1
    export LDFLAGS="${LDFLAGS} -static-libgcc"
fi
autoreconf -v

# Specify the native compiler for the programs that need to be run on the host
export CCAUX=${CC_BUILD}

# Fix include path
export CPPFLAGS="$CPPFLAGS -I${includedir}"

# Add the path for our own zlib
export LDFLAGS="$LDFLAGS -L${libdir}"

# Tesseract is not needed; iconv is only used by the disabled contributed drivers.
./configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --without-x \
    --without-local-zlib \
    --disable-contrib \
    --with-libiconv=no \
    --disable-cups \
    --without-tesseract

# create the binaries
make -j${nproc} so
make -j${nproc}

# install to prefixes
make install
if [[ "${target}" == *-mingw* ]]; then
    # make soinstall creates broken symlinks for mingw
    gs_major=$(awk -F= '$1 == "GS_VERSION_MAJOR" {print $2}' base/version.mak)
    install -Dvm 755 "sobin/libgs-${gs_major}.${dlext}" "${libdir}/libgs-${gs_major}.${dlext}"
    ln -s "libgs-${gs_major}.${dlext}" "${libdir}/libgs.${dlext}"

    install -Dvm 755 "psi/iapi.h" "${includedir}/ghostscript/iapi.h"
    install -Dvm 755 "psi/ierrors.h" "${includedir}/ghostscript/ierrors.h"
    install -Dvm 755 "base/gserrors.h" "${includedir}/ghostscript/gserrors.h"

    install -Dvm 755 "sobin/gsc${exeext}" "${bindir}/gsc${exeext}"
    install -Dvm 755 "sobin/gsx${exeext}" "${bindir}/gsx${exeext}"
else
    make soinstall
fi
install_license LICENSE doc/COPYING
for license in brotli/LICENSE freetype/docs/FTL.TXT jbig2dec/LICENSE jpeg/README lcms2mt/COPYING libpng/LICENSE openjpeg/LICENSE tiff/LICENSE.md extract/COPYING; do
    install -Dvm 644 "${license}" "${prefix}/share/licenses/Ghostscript/${license}"
done
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

products = [
    ExecutableProduct("gs", :gs),
    ExecutableProduct("gsc", :gsc),
    ExecutableProduct("gsx", :gsx),
    LibraryProduct("libgs", :libgs),
    # These are shell wrappers around gs, not binary executables
    FileProduct("bin/dvipdf", :dvipdf),
    FileProduct("bin/eps2eps", :eps2eps),
    FileProduct("bin/gsbj", :gsbj),
    FileProduct("bin/gsdj", :gsdj),
    FileProduct("bin/gsdj500", :gsdj500),
    FileProduct("bin/gslj", :gslj),
    FileProduct("bin/gslp", :gslp),
    FileProduct("bin/gsnd", :gsnd),
    FileProduct("bin/pdf2dsc", :pdf2dsc),
    FileProduct("bin/pdf2ps", :pdf2ps),
    FileProduct("bin/pf2afm", :pf2afm),
    FileProduct("bin/pfbtopfa", :pfbtopfa),
    FileProduct("bin/pphs", :pphs),
    FileProduct("bin/printafm", :printafm),
    FileProduct("bin/ps2ascii", :ps2ascii),
    FileProduct("bin/ps2epsi", :ps2epsi),
    FileProduct("bin/ps2pdf", :ps2pdf),
    FileProduct("bin/ps2pdf12", :ps2pdf12),
    FileProduct("bin/ps2pdf13", :ps2pdf13),
    FileProduct("bin/ps2pdf14", :ps2pdf14),
    FileProduct("bin/ps2pdfwr", :ps2pdfwr),
    FileProduct("bin/ps2ps", :ps2ps),
    FileProduct("bin/ps2ps2", :ps2ps2),
    # header files
    FileProduct("include/ghostscript/iapi.h", :iapi_h),
    FileProduct("include/ghostscript/ierrors.h", :ierrors_h),
    FileProduct("include/ghostscript/gserrors.h", :gserrors_h),
]

dependencies = Dependency[
    Dependency("Zlib_jll"; compat="1.2.12"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"7", clang_use_lld=false, julia_compat="1.6")
