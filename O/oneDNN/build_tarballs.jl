# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilderBase: os
using BinaryBuilder, Pkg

name = "oneDNN"
version = v"2.5.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/oneapi-src/oneDNN.git", "a402b6905b82477999982470308ccaaa39966adb"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/oneDNN

mkdir build && cd build/
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DONEDNN_BUILD_EXAMPLES=OFF \
    -DONEDNN_BUILD_TESTS=OFF \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> nbits(p) == 64, platforms) # oneDNN supports 64 bit platforms only
filter!(p -> libc(p) != "musl", platforms) # musl fails to link with ssp(?)
filter!(p -> os(p) != "windows", platforms) # windows fails to compile: error: ‘_MCW_DN’ was not declared in this scope
platforms = expand_cxxstring_abis(platforms)

intel_openmp_platforms = filter(p -> arch(p) == "x86_64", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libdnnl", "dnnl"], :libdnnl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("IntelOpenMP_jll"; platforms = intel_openmp_platforms)
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat = "1.6")
