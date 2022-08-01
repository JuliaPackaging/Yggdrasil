# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libiio"
version = v"0.24.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/analogdevicesinc/libiio.git", "c4498c27761d04d4ac631ec59c1613bfed079da5")
]

dependencies = [
    Dependency("libusb_jll", compat="~1.0.24"),
    Dependency("XML2_jll", compat="~2.9.12"),
    Dependency("libaio_jll", compat="~0.3.112"),
]

# Bash recipe for building across all platforms
script = raw"""
cd libiio

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DHAVE_DNS_SD=OFF \
    -DENABLE_IPV6=OFF \
    -DWITH_TESTS=OFF \
    -DOSX_FRAMEWORK=OFF \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libiio", :libiio)
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
