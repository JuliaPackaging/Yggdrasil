include("../common.jl")

version = v"3.2.2"

sources = [
    GitSource(
        "https://github.com/argtable/argtable3.git",
        "55c4f6285e2f9b2f0cc96ae8212b7b943547c3dd",
    ),
]

script = raw"""
cd $WORKSPACE/srcdir/argtable3
install_license LICENSE
CC=gcc
CXX=g++
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude = Sys.iswindows)
platforms = expand_cxxstring_abis(platforms)

products = [LibraryProduct("libargtable3", :libargtable3)]

build_argtable(version, sources, script, platforms, products)
