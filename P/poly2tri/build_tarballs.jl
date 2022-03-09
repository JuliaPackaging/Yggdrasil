# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "poly2tri"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/jhasse/poly2tri.git", "136fa7acfc95cf06a3488102f0cff039b7f3485c"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/poly2tri/

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cmake-edits.patch

cmake -GNinja . \
-DCMAKE_INSTALL_PREFIX=${prefix} \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release \
-DP2T_BUILD_TESTS=OFF \
-DP2T_BUILD_TESTBED=OFF

cmake --build .
ninja -j${nproc} install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct("libpoly2tri", :libpoly2tri)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
