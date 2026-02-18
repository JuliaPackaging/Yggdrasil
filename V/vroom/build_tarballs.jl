using BinaryBuilder, Pkg

name = "vroom"
version = v"1.14.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/VROOM-Project/vroom.git", "1fd711bc8c20326dd8e9538e2c7e4cb1ebd67bdb"),
    GitSource("https://github.com/chriskohlhoff/asio.git", "asio-1-30-2"),
]

# Bash recipe for building across all platforms
# ASIO is expected at ../asio (sibling of vroom); add its include path to the makefile
script = raw"""
cd $WORKSPACE/srcdir
cd asio/asio
./autogen.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
cd ../../vroom
git submodule init
git submodule update
cd src
make
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GLPK_jll", uuid="e8aa6df9-e6ca-548a-97ff-1f85fc5b8b98"))
    Dependency(PackageSpec(name="jq_jll", uuid="f8f80db2-c0ba-59e9-a5c3-38d72e3c5ac2"))
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"))
]

# Build the tarballs, and possibly a `build.jl` as well.
# Need GCC 11 for full C++20 support (e.g. `using enum`, which vroom uses)
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"11")
