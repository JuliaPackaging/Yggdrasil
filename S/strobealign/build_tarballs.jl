# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "strobealign"
version = v"0.13.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ksahlin/strobealign.git", "11aaa5cbb60eba080e63dbe49b4506c8308b42b9")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/strobealign
cmake -B build -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="-msse4.2" -DCMAKE_CXX_FLAGS="-msse4.2"
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# Same limitations as isa_l
filter!(p -> arch(p) == "x86_64" && !Sys.isapple(p), platforms)


# The products that we will ensure are always built
products = [
    ExecutableProduct("strobealign", :strobealign)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"11", julia_compat="1.6")
