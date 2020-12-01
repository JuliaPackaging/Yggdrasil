# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libfacedetect"
# I guess it's v3 https://github.com/ShiqiYu/libfacedetection/blob/master/ChangeLog#L3
# but doesn't really have any versions
version = v"3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ShiqiYu/libfacedetection", "36783e346c596968f6648bdfdc76efc8c6f082a9"),
]

# Bash recipe for building across all platforms
script = raw"""
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=install -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release -DDEMO=OFF
cmake --build . --config Release
cmake --build . --config Release --target install
cd ..
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libfacedetect", :libfacedetect),
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
