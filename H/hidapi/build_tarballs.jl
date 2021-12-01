# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "hidapi"
version = v"0.10.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/libusb/hidapi.git", "f6d0073fcddbdda24549199445e844971d3c9cef")
]

# Script template (structure is the same for all platforms, directory for make differs)
# The additional eudev-dev package is to allow the ./configure step. For linux there are
# two backends: linux and libusb. This script builds only the 'libusb' backend
# which doesn't needs libudev...
script = raw"""
cd $WORKSPACE/srcdir/hidapi/

if [[ ${target} == *-linux-* ]]; then
    # We need this only to trick `configure` into thinking that udev is available,
    # but we aren't going to actually use it
    apk add eudev-dev
fi

./bootstrap
./configure --prefix=${prefix} --host=${target} --build=${MACHTYPE}
# Install all license files
install_license LICENSE*.txt

if [[ ${target} == *-mingw* ]]; then
    cd windows
elif [[ ${target} == *-apple-* ]]; then
    cd mac
else
    cd libusb
fi

make -j${nproc}
make install
"""

products = [
    LibraryProduct(["libhidapi","libhidapi-libusb"], :hidapi)
]

dependencies = [
    Dependency("libusb_jll")
]

platforms = [p for p in supported_platforms() if !Sys.isfreebsd(p)]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
