# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "assimp"
version = v"5.2.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/assimp/assimp.git",
              "9519a62dd20799c5493c638d1ef5a6f484e5faf1"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd assimp/
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DASSIMP_BUILD_ASSIMP_TOOLS=false \
    -DASSIMP_BUILD_TESTS=false \
    -DASSIMP_INSTALL_PDB=false \
    -DASSIMP_DOUBLE_PRECISION=false \
    -DINJECT_DEBUG_POSTFIX=false \

make -j${nproc}
make install
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if p != Platform("i686", "linux"; libc="musl") &&
                                                 p != Platform("armv7l", "linux"; libc="musl") &&
                                                 p != Platform("aarch64", "macos") &&
                                                 p != Platform("x86_64", "macos") &&
                                                 p != Platform("powerpc64le", "linux"; libc="glibc")
            ]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libassimp", :libassimp)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"12", julia_compat="1.6")
