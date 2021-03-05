# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Ghostscript"
version = v"9.52"

# Collection of sources required to build
sources = [
    ArchiveSource(
        "https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs9533/ghostscript-9.53.3.tar.gz", # URL
        "6eaf422f26a81854a230b80fd18aaef7e8d94d661485bd2e97e695b9dce7bf7f" # SHA256 hash
    ),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ghostscript*
if [[ "${target}" == *-mingw* ]]; then
    # Patches from
    # https://github.com/msys2/MINGW-packages/tree/d87e68ae356d773901e5c477854312e5de0548cf/mingw-w64-ghostscript
    atomic_patch -p1 ../patches/001-mingw-build.patch
    atomic_patch -p1 ../patches/002-ghostscript-sys-zlib.patch
    atomic_patch -p1 ../patches/003-libspectre.patch
    atomic_patch -p1 ../patches/004-FT_CALLBACK_DEF-deprecated.patch
fi

# Specify the native compiler for the programs that need to be run on the host
export CCAUX=${CC_BUILD}

# configure the Makefiles
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
  --without-x --disable-contrib --disable-cups

# create the binaries
make -j${nproc}

# install to prefixes
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

products = [
    ExecutableProduct("dvipdf", :dvipdf),
    ExecutableProduct("eps2eps", :eps2eps),
    ExecutableProduct("gs", :gs),
    ExecutableProduct("gsbj", :gsbj),
    ExecutableProduct("gsdj", :gsdj),
    ExecutableProduct("gsdj500", :gsdj500),
    ExecutableProduct("gslj", :gslj),
    ExecutableProduct("gslp", :gslp),
    ExecutableProduct("gsnd", :gsnd),
    ExecutableProduct("pdf2dsc", :pdf2dsc),
    ExecutableProduct("pdf2ps", :pdf2ps),
    ExecutableProduct("pf2afm", :pf2afm),
    ExecutableProduct("pfbtopfa", :pfbtopfa),
    ExecutableProduct("pphs", :pphs),
    ExecutableProduct("printafm", :printafm),
    ExecutableProduct("ps2ascii", :ps2ascii),
    ExecutableProduct("ps2epsi", :ps2epsi),
    ExecutableProduct("ps2pdf", :ps2pdf),
    ExecutableProduct("ps2pdf12", :ps2pdf12),
    ExecutableProduct("ps2pdf13", :ps2pdf13),
    ExecutableProduct("ps2pdf14", :ps2pdf14),
    ExecutableProduct("ps2pdfwr", :ps2pdfwr),
    ExecutableProduct("ps2ps", :ps2ps),
    ExecutableProduct("ps2ps2", :ps2ps2),
]

dependencies = [
    Dependency("Libtiff_jll")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
