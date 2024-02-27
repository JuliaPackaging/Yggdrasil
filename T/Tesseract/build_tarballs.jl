# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Tesseract"
version = v"5.1.0"

# Collection of sources required to build Tesseract
sources = [
    GitSource("https://github.com/tesseract-ocr/tesseract.git",
                  "c2a3efe2824e1c8a0810e82a43406ba8e01527c4"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tesseract

atomic_patch -p1 "$WORKSPACE/srcdir/patches/disable_fast_math.patch"

./autogen.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install

install_license ./LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libtesseract", :libtesseract),
    ExecutableProduct("tesseract", :tesseract),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Giflib_jll"),
    Dependency("JpegTurbo_jll"),
    Dependency("libpng_jll"),
    Dependency("Libtiff_jll"; compat="~4.3, ~4.4"),
    Dependency("Zlib_jll"),
    Dependency("Leptonica_jll"; compat="~1.82"),
    Dependency("CompilerSupportLibraries_jll"),
    # Optional dependencies
    # Dependency("ICU_jll"),
    Dependency("Cairo_jll"; compat="1.16.1"),
    Dependency("Pango_jll"; compat="1.47.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"7",
    julia_compat="1.6"
)
