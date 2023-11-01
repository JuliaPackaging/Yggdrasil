# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "yaml_cpp"
version = v"0.5.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/jbeder/yaml-cpp.git", "b57efe94e7d445713c29f863adb8c23438eaa217"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/yaml-cpp*/

patch -p1 < ../patches/missing_boost_next_prior_include.patch

if [[ $target == *-apple-darwin* || $target == *-freebsd* ]]; then
    cmake_extra_args=-DCMAKE_C_FLAGS=-D_LIBCPP_ENABLE_CXX17_REMOVED_FEATURES
fi

mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DYAML_CPP_BUILD_TOOLS=OFF \
    $cmake_extra_args

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct(["libyaml-cpp", "yaml-cpp"], :libyaml_cpp)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec("boost_jll", v"1.76.0")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"6")
