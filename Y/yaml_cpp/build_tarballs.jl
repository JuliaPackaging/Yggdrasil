# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "yaml_cpp"
version = v"0.8.1" # Corresponds to v0.8.0.  We had to change the version number to bump the compat bound, from next release we can go back to follow upstream version

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/jbeder/yaml-cpp.git", "f7320141120f720aecc4c32be25586e7da9eb978"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/yaml-cpp*/
mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DYAML_BUILD_SHARED_LIBS=ON \
    -DYAML_CPP_BUILD_TESTS=OFF

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct("libyaml-cpp", :libyaml_cpp)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"6")

# Build trigger: 1
