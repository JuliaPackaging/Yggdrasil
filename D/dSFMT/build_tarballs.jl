using BinaryBuilder

name = "dSFMT"
version = v"2.2.3"

# Collection of sources required to build Ogg
sources = [
   "http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/SFMT/dSFMT-src-$(version).tar.gz" =>
   "82344874522f363bf93c960044b0a6b87b651c9565b6312cf8719bb8e4c26a0e",
   "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/dSFMT*/

atomic_patch -p1 $WORKSPACE/srcdir/patches/dSFMT.h.patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/dSFMT.c.patch

FLAGS=(
    -DNDEBUG -DDSFMT_MEXP=19937 -fPIC -DDSFMT_DO_NOT_USE_OLD_NAMES
    -O3 -finline-functions -fomit-frame-pointer -fno-strict-aliasing
    --param max-inline-insns-single=1800 -Wmissing-prototypes -Wall -std=c99 -shared
)

if [[ ${target} == *mingw* ]]; then
    TARGET=${prefix}/bin/libdSFMT.${dlext}
else
    TARGET=${prefix}/lib/libdSFMT.${dlext}
fi

if [[ ${target} == x86_64* ]]; then
    FLAGS+=(-msse2 -DHAVE_SSE2)
fi

${CC} ${FLAGS[@]} ${CFLAGS} ${CPPFLAGS} ${LDFLAGS} -o ${TARGET} dSFMT.c
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = prefix -> [
    LibraryProduct(prefix, "libdSFMT", :libdSFMT),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/JuliaWeb/MbedTLSBuilder/releases/download/v0.16.0/build_MbedTLS.v2.13.1.jl",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/LibSSH2-v1.8.0-0/build_LibSSH2.v1.8.0.jl",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/LibCURL-v7.61.0-1/build_LibCURL.v7.61.0.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
