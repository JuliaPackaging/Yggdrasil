# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libusb_compat"
version = v"0.18"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/libusb/libusb-compat-0.1.git",
              "3e8a88d296b5405902c22d2ada61937bd9a89415"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd libusb-compat-0.1/
./bootstrap.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-udev
make -j${nproc}
make install
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;exclude=!Sys.islinux)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libusb", "libusb-0.1"], :libusb)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(Sys.islinux, platforms)),
    Dependency("libusb_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"5")
