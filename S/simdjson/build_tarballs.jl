# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "simdjson"
version = v"0.9.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/simdjson/simdjson.git", "911b06186bc32f000cfb6d9e28210509e0878501")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd simdjson/
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DSIMDJSON_ENABLE_THREADS=ON ..
make -j ${nprocs}
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental = true)
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libsimdjson", :libsimdjson)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8.1.0", julia_compat = "1.6")
