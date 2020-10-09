# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "x264"
version = v"2020.07.14"

# Collection of sources required to build x264
sources = [
    ArchiveSource("https://code.videolan.org/videolan/x264/-/archive/db0d417728460c647ed4a847222a535b00d3dbcb/x264-db0d417728460c647ed4a847222a535b00d3dbcb.tar.gz",
                  "b79b7038ce083f152fdd35da2f0d770ac9189fa2319fd09012567bc3a33737af"),          
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/x264-*
if [[ "${target}" == x86_64* ]] || [[ "${target}" == i686* ]]; then
    apk add nasm
    export AS=nasm
else
    export AS="${CC}"
fi
./configure --prefix=$prefix --host=$target --enable-shared --enable-pic --disable-static
# Remove unsafe compilation flag
sed -i 's/ -ffast-math//g' config.mak
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("x264", :x264),
    LibraryProduct("libx264", :libx264),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
