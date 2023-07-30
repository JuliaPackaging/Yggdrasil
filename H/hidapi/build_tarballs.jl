# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "hidapi"
version = v"0.14.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/libusb/hidapi.git", "d3013f0af3f4029d82872c1a9487ea461a56dee4"),
]

# Script template (structure is the same for all platforms, directory for make differs)
# The additional eudev-dev package is to allow configuring the build. For linux there are
# two backends: linux and libusb. This script builds only the 'libusb' backend
script = raw"""
cd $WORKSPACE/srcdir/
mkdir build
cd build

if [[ ${target} == *-linux-* ]]; then
    # We need this only to trick `configure` into thinking that udev is available,
    # but we aren't going to actually use it
    apk add eudev-dev
    linuxflags="-DHIDAPI_WITH_HIDRAW=false"
fi

cmake  \
    ../hidapi \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    ${linuxflags} \
    ..

cmake --build . --target install
install_license ../hidapi/LICENSE*.txt
"""

platforms = supported_platforms()

products = [
    LibraryProduct(["libhidapi", "libhidapi-libusb"], :hidapi)
]

dependencies = [
    Dependency("libusb_jll", platforms=filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms))
]


build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"5.2.0")
