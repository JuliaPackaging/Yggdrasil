# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LASzip"
version = v"3.4.3000"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/LASzip/LASzip.git", "1ab671e42ff1f086e29d5b7e300a5026e7b8d69b")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

# Patch to find unordered_map from tr1, logic there doesn't work for MINGW32.
if [[ "${target}" == *-mingw* ]]; then
    sed -i '/add_definitions(-DUNORDERED)/d' LASzip/src/CMakeLists.txt;  
fi

mkdir LASzip/build
cd LASzip/build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_CXX_FLAGS="-std=c++11" -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_VERBOSE_MAKEFILE=OFF ..
cmake --build . --target install --config Release
"""


# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct(["liblaszip", "liblaszip3"], :liblaszip)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
