# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "sais"
version = v"2.4.1"

# Collection of sources required to complete build
sources = [
    "https://sites.google.com/site/yuta256/sais-2.4.1.zip" =>
    "467b7b0b6ec025535c25e72174d3cc7e29795643e19a3f8a18af9ff28eca034a",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sais-2.4.1/
if [[ $nbits == 64 ]]; then
  build64=ON
else
  build64=OFF
fi
mkdir build && cd build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=$CMAKE_TARGET_TOOLCHAIN -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DBUILD_EXAMPLES=OFF -DBUILD_SAIS64=$build64 ..
make -j$nproc
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
libsais = LibraryProduct("libsais", :libsais)
libsais64 = LibraryProduct("libsais64", :libsais64)
products = [libsais]
products64 = [libsais, libsais64]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
for p in platforms
    build_tarballs(ARGS, name, version, sources, script, [p], wordsize(p)==64 ? products64 : products, dependencies)
end
