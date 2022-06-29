# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LibTorchCAPI"
version = v"1.7.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/data-efficient-ml/ThArrays.jl.git",
              "bb6c6a63ffd0d11e0df42d5faab2cdf9426e1189"),
]

# Bash recipe for building across all platforms
script_file = joinpath(dirname(@__FILE__), "build_dylib.sh")
if !isfile(script_file)
    script_file = joinpath(dirname(@__FILE__), "L/libtorch_capi/build_dylib.sh")
end
script = read(script_file, String)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi = "cxx11")
    # MacOS(:x86_64), # can't build it on MacOS SDK
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libtorch_capi", :libtorch_capi, dont_dlopen = true),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version = v"8")
