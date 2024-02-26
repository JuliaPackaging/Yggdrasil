# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "DynamO"
version = v"1.7.6"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/toastedcrumpets/DynamO/archive/refs/tags/dynamo-$(replace("$version", "." => "-")).tar.gz", "99c9abc35b3665d9c3c94d625f1661824c456f90b8e023926d49092fbf7c59de")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="-lrt" DynamO-*/
cmake --build . --target install -- -j${nproc}
install_license DynamO-*/LICENSE.txt 
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p -> libc(p) != "glibc")

platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("dynarun", :dynarun),
    ExecutableProduct("dynamod", :dynamod),
    ExecutableProduct("dynapotential", :dynapotential),
    ExecutableProduct("dynahist_rw", :dynahist_rw)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="boost_jll", uuid="28df3c45-c428-5900-9ff8-a3135698ca75"); compat="=1.76.0")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8")
