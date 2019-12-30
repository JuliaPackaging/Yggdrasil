# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libusb"
version = v"1.0.23"

# Collection of sources required to complete build
sources = [
    "https://github.com/libusb/libusb.git" =>
    "e782eeb2514266f6738e242cdcb18e3ae1ed06fa",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd libusb/
./bootstrap.sh 
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-udev
make -j${nproc}
make install
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libusb","libusb-1.0"], :libusb)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
