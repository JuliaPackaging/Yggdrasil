# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libusb"
version = v"1.0.29"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/libusb/libusb.git",
              "15a7ebb4d426c5ce196684347d2b7cafad862626"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libusb/
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
    LibraryProduct(["libusb", "libusb-1", "libusb-1.0"], :libusb)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(Sys.islinux, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
