# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "x264"
version = v"2019.05.25"

# Collection of sources required to build x264
sources = [
    "https://download.videolan.org/pub/videolan/x264/snapshots/x264-snapshot-20190525-2245-stable.tar.bz2" =>
    "638581a18bff8e9375211955422eff145011c8ccfd0994d43bd194cd82984f7a",

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
./configure --prefix=$prefix --host=$target --enable-static --enable-pic
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("x264", :x264)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
