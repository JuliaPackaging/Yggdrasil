using BinaryBuilder

name = "HelloWorldCxx"
version = v"1.1.1"

# No sources, we're just building the testsuite
sources = [
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${prefix}/bin
c++ -o ${prefix}/bin/hello_world${exeext} -g -O2 /usr/share/testsuite/cxx/hello_world/hello_world.cc
install_license /usr/share/licenses/MIT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("hello_world", :hello_world),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"6")
