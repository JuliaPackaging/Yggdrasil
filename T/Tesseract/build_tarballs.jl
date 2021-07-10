# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Tesseract"
version = v"4.1.1"

# Collection of sources required to build Tesseract
sources = [
    ArchiveSource("https://github.com/tesseract-ocr/tesseract/archive/$(version).tar.gz",
                  "2a66ff0d8595bff8f04032165e6c936389b1e5727c3ce5a27b3e059d218db1cb"),
    DirectorySource("./bundled")
]

version = v"4.1.100" # <--- This version number is a lie, we just need to bump it to build for experimental platforms

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tesseract-*/
if [[ "${target}" == *-musl* ]] || [[ "${target}" == *-freebsd* ]]; then
    # Apply layman patch to make this work
    atomic_patch -p1 "$WORKSPACE/srcdir/patches/sys_time_musl_freebsd.patch"
fi
atomic_patch -p1 "$WORKSPACE/srcdir/patches/disable_fast_math.patch"
./autogen.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))

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
    Dependency("Libtiff_jll"; compat="4.3.0"),
    Dependency("Zlib_jll"),
    Dependency("Leptonica_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    # Optional dependencies
    # Dependency("ICU_jll"),
    Dependency("Cairo_jll"; compat="1.16.1"),
    Dependency("Pango_jll"; compat="1.47.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
