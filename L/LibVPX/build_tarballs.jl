# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg.BinaryPlatforms

name = "LibVPX"
version = v"1.8.0"

# Collection of sources required to build LibVPX
sources = [
    "https://github.com/webmproject/libvpx/archive/v1.8.0.tar.gz" =>
    "86df18c694e1c06cc8f83d2d816e9270747a0ce6abe316e93a4f4095689373f6",
    "./patches"
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/libvpx-*/
sed -i 's/cp -p/cp/' build/make/Makefile
patch -p1 < $WORKSPACE/srcdir/macos.patch

mkdir vpx_build && cd vpx_build
apk add diffutils yasm

if [[ "${target}" == i686-linux-* ]]; then
    export TARGET=x86-linux-gcc
elif [[ "${target}" == x86_64-linux-* ]]; then
    export TARGET=x86_64-linux-gcc
elif [[ "${target}" == arm-linux-* ]]; then
    export TARGET=armv7-linux-gcc
elif [[ "${target}" == aarch64-linux-* ]]; then
    export TARGET=arm64-linux-gcc
elif [[ "${target}" == powerpc64le-linux-* ]]; then
    export TARGET=ppc64le-linux-gcc
elif [[ "${target}" == x86_64-apple-* ]]; then
    export TARGET=x86_64-darwin14-gcc
elif [[ "${target}" == i686-w64-mingw32 ]]; then
    export TARGET=x86-win32-gcc
elif [[ "${target}" == x86_64-w64-mingw32 ]]; then
    export TARGET=x86_64-win64-gcc
    export CFLAGS="${CFLAGS} -fno-asynchronous-unwind-tables"
elif [[ "${target}" == *freebsd* ]]; then
    export TARGET=generic-gnu
    export CONFIG_OPTS="--disable-multithread"
fi

../configure --prefix=$prefix --target=${TARGET} \
    --as=yasm \
    --enable-postproc \
    --enable-pic \
    --enable-vp8 \
    --enable-vp9 \
    --enable-vp9-highbitdepth \
    --enable-runtime-cpu-detect \
    ${CONFIG_OPTS}
echo "SRC_PATH_BARE=.." >> config.mk
echo "target=libs" >> config.mk
make -j${nproc}
make install
"""

# Disable ppc64le for now due to altivec problems
platforms = filter(p -> arch(p) != :powerpc64le, supported_platforms())

# The products that we will ensure are always built
products = [
    # While we want this, it's not available on windows.  :/
    #LibraryProduct("libvpx", :libvpx),
    FileProduct("\${libdir}/libvpx.a", :libvpx),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")
