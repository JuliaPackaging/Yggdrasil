# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LibVPX"
version = v"1.8.1"

# Collection of sources required to build LibVPX
sources = [
    "https://github.com/webmproject/libvpx/archive/v$(version).tar.gz" =>
    "df19b8f24758e90640e1ab228ab4a4676ec3df19d23e4593375e6f3847dee03e",
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/libvpx-*/
sed -i 's/cp -p/cp/' build/make/Makefile

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

# pkgconfig file on Windows is installed to ${libdir}/pkgconfig,
# we have to move it to ${prefix}/lib/pkgconfig/
if [[ "${target}" == *-mingw* ]] && [[ -d "${libdir}/pkgconfig" ]] ; then
    mkdir -p "${prefix}/lib"
    mv "${libdir}/pkgconfig" "${prefix}/lib/pkgconfig"
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

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
