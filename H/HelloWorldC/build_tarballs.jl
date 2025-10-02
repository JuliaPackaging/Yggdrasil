using BinaryBuilder

name = "HelloWorldC"
version = v"1.4.1"

# No sources, we're just building the testsuite
sources = [
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${bindir}
cc -o ${prefix}/bin/hello_world${exeext} -g -O2 /usr/share/testsuite/c/hello_world/hello_world.c

# Also build with cmake
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make -j${nproc}

install_license /usr/share/licenses/MIT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("hello_world", :hello_world),

    # This ExecutableProduct is used in tests that change one of the paths
    ExecutableProduct("hello_world", :hello_world_doppelganger),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compression_format="xz")
