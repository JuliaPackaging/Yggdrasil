# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libiio"
version = v"0.23.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/analogdevicesinc/libiio.git", "92d6a35f3d8d721cda7d6fe664b435311dd368b4")
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
    ..
make -j${nproc}
if [[ "${target}" == *-apple-* ]]; then
    cp -r iio.framework ${libdir}
else
    make install
fi
"""

include("../../fancy_toys.jl")

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> !Sys.isapple(p), supported_platforms(;experimental=true))
platforms_macos = filter!(p -> Sys.isapple(p), supported_platforms(;experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct("libiio", :libiio)
]

products_apple = [
    FrameworkProduct("iio", :libiio)
]

# Build the tarballs, and possibly a `build.jl` as well.
if any(should_build_platform.(triplet.(platforms_macos)))
    build_tarballs(ARGS, name, version, sources, script, platforms_macos, products_apple, dependencies; julia_compat="1.6")
end
if any(should_build_platform.(triplet.(platforms)))
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
end