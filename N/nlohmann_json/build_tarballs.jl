# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "nlohmann_json"
version = v"3.12.0"

sources = [
   GitSource("https://github.com/nlohmann/json/", "55f93686c01528224f448c19128836e7df245f72")
]

script = raw"""
cd $WORKSPACE/srcdir

mkdir build
cd build

CMAKE_ARGS="-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
            -DCMAKE_FIND_ROOT_PATH=${prefix} \
            -DCMAKE_INSTALL_PREFIX=${prefix}"

cmake .. ${CMAKE_ARGS}

make -j${nproc} install

"""

platforms = [AnyPlatform()]

products = [
   FileProduct("include/nlohmann/json.hpp", :json_hpp),
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
               julia_compat="1.6", preferred_gcc_version = v"5")
