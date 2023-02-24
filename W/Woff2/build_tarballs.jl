# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Woff2"
version = v"1.0.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/google/woff2/archive/v$(version)/woff2-$(version).tar.gz", "add272bb09e6384a4833ffca4896350fdb16e0ca22df68c0384773c67a175594")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
install_license woff2-*/LICENSE
cd woff2-*
mkdir out
cd out
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libwoff2common", :libwoff2common),
    LibraryProduct("libwoff2enc", :libwoff2enc),
    LibraryProduct("libwoff2dec", :libwoff2dec)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="brotli_jll", uuid="4611771a-a7d2-5e23-8d00-b1becdba1aae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
