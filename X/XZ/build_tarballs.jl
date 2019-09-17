# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "XZ"
version = v"5.2.4"

# Collection of sources required to build XzBuilder
sources = [
    "https://tukaani.org/xz/xz-$(version).tar.xz" =>
    "9717ae363760dedf573dad241420c5fea86256b65bc21d2cf71b2b12f0544f4b",
    "https://tukaani.org/xz/xz-$(version)-windows.zip" =>
    "9a5163623f435b6fa0844b6b884babd6bf4f8d876ae2d8134deeb296afd49c61",
]

# Bash recipe for building across all platforms
script = raw"""
if [ ${target} = "x86_64-w64-mingw32" ]; then
    mkdir -p ${WORKSPACE}/destdir/bin/
    cp bin_x86-64/liblzma.dll ${WORKSPACE}/destdir/bin/
elif [ ${target} = "i686-w64-mingw32" ]; then
    mkdir -p ${WORKSPACE}/destdir/bin/
    cp bin_i686/liblzma.dll ${WORKSPACE}/destdir/bin/
else
    cd $WORKSPACE/srcdir/xz-*
    ./configure --prefix=${prefix} --host=${target} --with-pic CFLAGS="${CFLAGS} -fPIC" CXXFLAGS="${CXXFLAGS} -fPIC"
    make -j${nproc}
    make install
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("liblzma", :liblzma)
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
