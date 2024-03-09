# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "cppcheck"
version = v"2.13.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/danmar/cppcheck.git", "da29903ffcbde465b6c2b47e8dc38277743f47ec"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cppcheck/

mkdir build && cd build

cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_GUI=OFF \
      -DUSE_MATCHCOMPILER=OFF \
      -DDISABLE_DMAKE=ON \
      -DBUILD_TESTS=OFF \
      -DHAVE_RULES=ON \
      ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(exclude=Sys.isfreebsd))

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("cppcheck", :cppcheck),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("PCRE_jll"; compat="8.44.0")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
