# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Ghostscript"
version = v"9.53.3"

# Collection of sources required to build
sources = [
    ArchiveSource(
        "https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs$(version.major)$(version.minor)$(version.patch)/ghostscript-$(version).tar.gz", # URL
        "6eaf422f26a81854a230b80fd18aaef7e8d94d661485bd2e97e695b9dce7bf7f" # SHA256 hash
    ),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ghostscript*

if [[ "${target}" == *-mingw* ]]; then
    # Patches adapted from
    # https://github.com/msys2/MINGW-packages/tree/d87e68ae356d773901e5c477854312e5de0548cf/mingw-w64-ghostscript
    # (we don't need to patch configure.ac)
    atomic_patch -p1 ../patches/001-mingw-build.patch
    atomic_patch -p1 ../patches/003-libspectre.patch
    atomic_patch -p1 ../patches/004-FT_CALLBACK_DEF-deprecated.patch
    # Patch adapted from
    # https://github.com/mxe/mxe/commit/3fee463ee24536144b053cc519cf963afb08dfb4
    atomic_patch -p1 ../patches/005-fix-conflicting-types-gp_local_arg_encoding_get_codepoint.patch
fi

# Specify the native compiler for the programs that need to be run on the host
export CCAUX=${CC_BUILD}

# configure the Makefiles
./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --without-x \
    --disable-contrib \
    --disable-cups

# create the binaries
make -j${nproc}

# install to prefixes
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

products = [
    ExecutableProduct("gs", :gs),
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
]

dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
