# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg.BinaryPlatforms

name = "FriBidi"
version = v"1.0.5"

# Collection of sources required to build FriBidi
sources = [
    "https://github.com/fribidi/fribidi.git" =>
    "0f849e344d446934b4ecdbe9edc32abd29029731",
    "https://github.com/mesonbuild/meson/releases/download/0.51.2/meson-0.51.2.tar.gz" =>
    "23688f0fc90be623d98e80e1defeea92bbb7103bf9336a5f5b9865d36e892d76",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/fribidi/
MESON="$WORKSPACE/srcdir/meson-0.51.2/meson.py"
mkdir build
cd build

CC=${CC_FOR_BUILD}
AR=${AR_FOR_BUILD}
LD=${LD_FOR_BUILD}
NM=${NM_FOR_BUILD}
STRIP=${STRIP_FOR_BUILD}
LDFLAGS=""

$MESON .. -Ddocs=false --cross-file="/opt/${target}/${target}.meson"
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if !(p isa Union{MacOS,FreeBSD})]

# The products that we will ensure are always built
products = [
    LibraryProduct("libfribidi", :libfribidi),
    ExecutableProduct("fribidi", :fribidi)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
