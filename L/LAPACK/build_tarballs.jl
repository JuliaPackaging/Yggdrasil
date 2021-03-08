using BinaryBuilder

name = "LAPACK"
version = v"3.9.0"

# Collection of sources required to build lapack
sources = [
    GitSource("https://github.com/Reference-LAPACK/lapack",
              "6acc99d5f39130be7cec00fb835606042101a970"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lapack*

mkdir build && cd build
cmake .. \
   -DCMAKE_INSTALL_PREFIX="$prefix" \
   -DCMAKE_FIND_ROOT_PATH="$prefix" \
   -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
   -DCMAKE_BUILD_TYPE=Release \
   -DBUILD_SHARED_LIBS=ON

VERBOSE=ON cmake --build build --config Release --target install -- -j${nproc}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms(;experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct("liblapack", :liblapack),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
        Dependency("CompilerSupportLibraries_jll")
        Dependency("libblastrampoline_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
