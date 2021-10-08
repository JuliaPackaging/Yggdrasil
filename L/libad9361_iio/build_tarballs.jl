# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libad9361_iio"
version = v"0.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/analogdevicesinc/libad9361-iio.git", "8ac95f3325c18c2e34cd9cfd49c7b63d69a0a9d2")
]

dependencies = [
    Dependency("libiio_jll"; compat="~0.23.0")
]

# Bash recipe for building across all platforms
script = raw"""
cd libad9361-iio

mkdir build && cd build
if [[ "${target}" == *-apple-* ]]; then
    cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_BUILD_TYPE=Release \
        -DLIBIIO_INCLUDEDIR=${libdir}/iio.framework/Versions/0.23/Headers/ \
        -DLibIIO_LIBRARY=${libdir}/iio.framework/Versions/0.23/iio \
        ..
    make -j${nproc}
    cp -r ad9361.framework ${libdir}
else
    cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ..
    make -j${nproc}
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
    LibraryProduct("libad9361", :libad9361),
]

products_apple = [
    FrameworkProduct("ad9361", :libad9361),
]

# Build the tarballs, and possibly a `build.jl` as well.
if any(should_build_platform.(triplet.(platforms_macos)))
    build_tarballs(ARGS, name, version, sources, script, platforms_macos, products_apple, dependencies; julia_compat="1.6")
end
if any(should_build_platform.(triplet.(platforms)))
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
end