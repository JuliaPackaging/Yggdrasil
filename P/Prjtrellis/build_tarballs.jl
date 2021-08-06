# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Prjtrellis"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/YosysHQ/prjtrellis.git", "dff1cbcb1bd30de7e96f8a059f2e19be1bb2e44d")
]

dependencies = [
    Dependency("Python_jll"; compat="~3.8.1"),
    Dependency("boost_jll"; compat="=1.76.0"), # max gcc7
]

# Bash recipe for building across all platforms
script = raw"""
cd prjtrellis/libtrellis
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> Sys.islinux(p), supported_platforms())
platforms = expand_cxxstring_abis(platforms)
# For some reason, building for CXX03 string ABI doesn't actually work, skip it
filter!(x -> cxxstring_abi(x) != "cxx03", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("ecpunpack", :ecpunpack),
    ExecutableProduct("ecppll", :ecppll),
    ExecutableProduct("ecpbram", :ecpbram),
    ExecutableProduct("ecppack", :ecppack),
    ExecutableProduct("ecpmulti", :ecpmulti),
    ExecutableProduct("ecpmulti", :ecpmulti),
    LibraryProduct("libtrellis", :libtrellis, ["lib/trellis", "lib64/trellis"]),
    LibraryProduct("pytrellis", :pytrellis, ["lib/trellis", "lib64/trellis"])
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
