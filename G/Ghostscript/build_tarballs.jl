# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Ghostscript"
version = v"9.52"

# Collection of sources required to build
sources = [
    ArchiveSource(
        "https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs952/ghostscript-9.52.tar.gz", # URL
        "c2501d8e8e0814c4a5aa7e443e230e73d7af7f70287546f7b697e5ef49e32176" # SHA256 hash
    ),
]

# Bash recipe for building across all platforms
script = raw"""
# initial setup
cd $WORKSPACE/srcdir/ghostscript*

# configure the Makefiles
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}

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

dependencies = Dependency[
    Dependency("Libtiff_jll")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
