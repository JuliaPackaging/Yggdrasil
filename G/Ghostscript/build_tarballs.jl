# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Ghostscript"
version = v"9.56.1"

# Collection of sources required to build
sources = [
    ArchiveSource(
        "https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs$(version.major)$(version.minor)$(version.patch)/ghostscript-$(version).tar.gz", # URL
        "1598b9a38659cce8448d42a73054b2f9cbfcc40a9b97eeec5f22d4d6cd1de8e6" # SHA256 hash
    ),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ghostscript*

if [[ "${target}" == *-mingw* ]]; then
    # Patches adapted from
    # https://github.com/msys2/MINGW-packages/tree/d87e68ae356d773901e5c477854312e5de0548cf/mingw-w64-ghostscript
    atomic_patch -p1 ../patches/001-mingw-build.patch
    atomic_patch -p1 ../patches/003-libspectre.patch
fi
autoreconf -v

# Specify the native compiler for the programs that need to be run on the host
export CCAUX=${CC_BUILD}

# configure the Makefiles.  Note we disable Tesseract because we don't need it
# at the moment, it requires a C++17 compiler, and configure for Windows fails
# because it doesn't find "threading".
./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --without-x \
    --disable-contrib \
    --disable-cups \
    --without-tesseract

# create the binaries
make -j${nproc} so
make -j${nproc}

# install to prefixes
make install
if [[ "${target}" == *-mingw* ]]; then
    # make soinstall creates broken symlinks for mingw
    install -Dvm 755 "sobin/libgs-9-55.${dlext}" "${libdir}/libgs-9-55.${dlext}"
    ln -s "${libdir}/libgs-9-55.${dlext}" "${libdir}/libgs-9.${dlext}"
    ln -s "${libdir}/libgs-9-55.${dlext}" "${libdir}/libgs.${dlext}"

    install -Dvm 755 "psi/iapi.h" "${includedir}/ghostscript/iapi.h"
    install -Dvm 755 "psi/ierrors.h" "${includedir}/ghostscript/ierrors.h"
    install -Dvm 755 "base/gserrors.h" "${includedir}/ghostscript/gserrors.h"

    install -Dvm 755 "sobin/gsc${exeext}" "${bindir}/gsc${exeext}"
    install -Dvm 755 "sobin/gsx${exeext}" "${bindir}/gsx${exeext}"
else
    make soinstall
fi
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
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
