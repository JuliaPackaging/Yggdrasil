# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LERC"
version = v"4.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Esri/lerc", "fbeb481120b79d05163f8544c645e9975920526f"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lerc

# Don't use `_assert` as identifier
sed -i -e 's/_assert/lerc_assert/g' src/LercLib/fpl_EsriHuffman.cpp src/LercLib/fpl_Lerc2Ext.cpp

cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}

cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libLerc", :libLerc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

# Build trigger: 2
