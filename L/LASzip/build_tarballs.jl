# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LASzip"
version = v"3.4.4001"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/LASzip/LASzip.git", "b6412aa4ac3f1fd44874c862de8e3eb7f672d495")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

mkdir LASzip/build
cd LASzip/build/

CMAKE_FLAGS=(
    -DCMAKE_INSTALL_PREFIX=$prefix
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DCMAKE_BUILD_TYPE=Release
)

# Prevents Mingw-w64 runtime failure:
# 32 bit pseudo relocation at 000000006A2417D2 out of range, targeting 00007FF91B307DD0, yielding the value 00007FF8B10C65FA
if [[ "${target}" == *-mingw* ]]; then
    CMAKE_FLAGS+=(-DCMAKE_CXX_FLAGS="-fno-gnu-unique")
fi

cmake ${CMAKE_FLAGS[@]} ..
cmake --build . --parallel ${nproc}
cmake --install .
"""


# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct(["liblaszip", "liblaszip3"], :liblaszip)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
