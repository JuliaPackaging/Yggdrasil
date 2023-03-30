# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CLN"
version = v"1.3.6"

# Collection of sources required to complete build
sources = [
    GitSource("git://www.ginac.de/cln.git", "d4621667b173aa197a2b23d63f561648c0ee2968")
]

# Bash recipe for building across all platforms
script = raw"""
mkdir $WORKSPACE/srcdir/cln-build/
cd $WORKSPACE/srcdir/cln-build/

cmake -GNinja \
    -DCMAKE_CXX_STANDARD=11 \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    $WORKSPACE/srcdir/cln
cmake --build . -j${nproc}
cmake --build . -t install

install_license $WORKSPACE/srcdir/cln/COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = Product[
    LibraryProduct("libcln", :libcln),
    ExecutableProduct("pi", :cln_pi)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"); compat="6.2.0")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
