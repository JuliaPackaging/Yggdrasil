# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "bladeRF"
version = v"2021.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Nuand/bladeRF.git", "3b4f42dee4300669d58718df4b85616a85b64904")
]

dependencies = [
    Dependency("libusb_jll", compat="~1.0.24"),
]

# Bash recipe for building across all platforms
script = raw"""
cd bladeRF/host
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> !Sys.iswindows(p) && !in(arch(p),("armv7l","armv6l")), supported_platforms(;experimental=true))

# The products that we will ensure are always built
products = Product[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")