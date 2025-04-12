# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LZFSE"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/lzfse/lzfse.git", "e634ca58b4821d9f3d560cdc6df5dec02ffc93fd")
]

script = raw"""
    cd $WORKSPACE/srcdir/lzfse

    if [[ "${target}" == *"freebsd"* ]]; then
        export CMAKE_TARGET_TOOLCHAIN=${CMAKE_TARGET_TOOLCHAIN.*}_gcc.cmake
    fi

    # Build with CMake
    cmake -B build \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%} \
        -DCMAKE_BUILD_TYPE=Release 

    cmake --build build --parallel ${nproc}
    cmake --install build

    install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("lzfse", :lzfse),
    LibraryProduct("liblzfse", :liblzfse),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
