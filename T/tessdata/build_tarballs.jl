# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "tessdata"
version = v"4.0.0"

# Collection of sources required to build tessdata
sources = [
    "https://github.com/tesseract-ocr/tessdata/archive/$(version).tar.gz" =>
    "38c637d3a1763f6c3d32e8f1d979f045668676ec5feb8ee1869ee77cedd31b08",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tessdata-*/
DEST_DIR="${prefix}/share/${SRC_NAME}"
mkdir -p "${DEST_DIR}"
cp *.traineddata "${DEST_DIR}"
qfind "${DEST_DIR}" -type f -exec chmod 0644 '{}' \;
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
