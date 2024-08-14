# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

include("../common.jl")
name = "oneAPI_Level_Zero_Loader"


# Bash recipe for building across all platforms
script = raw"""
cd level-zero
install_license LICENSE

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="musl"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libze_loader", :libze_loader),
    LibraryProduct("libze_tracing_layer", :libze_tracing_layer),
    LibraryProduct("libze_validation_layer", :libze_validation_layer),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("OpenCL_Headers_jll"),

    # The oneAPI Level Zero loader expects an implementation of its spec to be available.
    # That means we need to dlopen the implementation, e.g. Intel's NEO, before the loader!
    # To make sure that implementation sits at the same API level of the loader, we have
    # both packages depend on the oneAPI Level Zero Headers package.
    #
    # Users of these packages, e.g. oneAPI.jl, should only depend on the loader and an
    # implementation, but will need to make sure to load one before the other.
    Dependency("oneAPI_Level_Zero_Headers_jll"; compat="=$api_version"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"8")

# bump
