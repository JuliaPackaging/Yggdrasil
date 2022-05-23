# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Clingo"
version = v"5.5.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/potassco/clingo.git", "e1c20131b708439c7e1c317bb96b58e5a527b1a2")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/clingo
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("lpconvert", :lpconvert),
    ExecutableProduct("clingo", :clingo),
    ExecutableProduct("gringo", :gringo),
    ExecutableProduct("reify", :reify),
    ExecutableProduct("clasp", :clasp),
    LibraryProduct("libclingo",:libclingo)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5.2.0")
