using BinaryBuilder

name = "JpegTurbo"
version = v"2.0.1"

# Collection of sources required to build Ogg
sources = [
    "https://github.com/libjpeg-turbo/libjpeg-turbo/archive/$(version).tar.gz" =>
    "a30db8bcc8a0fab56998ea134233a8cdcb7ac81170e7d87f8bc900f02dda39d4",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libjpeg-turbo-*/

# Avengers; ASSEMBLE!
apk add yasm

mkdir build
cd build

cmake .. -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=/opt/$target/$target.toolchain
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = prefix -> [
    LibraryProduct(prefix, "libjpeg", :libjpeg),
    LibraryProduct(prefix, "libturbojpeg", :libturbojpeg),
    ExecutableProduct(prefix, "cjpeg", :cjpeg),
    ExecutableProduct(prefix, "djpeg", :djpeg),
    ExecutableProduct(prefix, "jpegtran", :jpegtran),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
