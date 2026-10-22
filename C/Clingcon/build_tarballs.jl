# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Clingcon"
version = v"5.2.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/potassco/clingcon.git", "8c476557facf9fc996ec67053a01b6273fd9baba")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/clingcon
mkdir build && cd build
cmake -G Ninja \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DPYCLINGCON_ENABLE=OFF \
    -DCLINGCON_BUILD_TESTS=OFF \
    -DCLINGCON_BUILD_SHARED=ON \
    ..
cmake --build . --target install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("clingcon", :clingcon),
    LibraryProduct("libclingcon",:libclingcon)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # clingcon links only against libclingo's C ABI (`libclingo.so.4`), but that
    # soname is not encoded in the JLL, so pair it with the clingo series it was
    # built against and rebuild on the next one.
    Dependency("Clingo_jll"; compat="~5.8.2")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8", julia_compat="1.6")
