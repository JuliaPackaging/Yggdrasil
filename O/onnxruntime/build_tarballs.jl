# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ONNXRuntime"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/microsoft/onnxruntime.git", "0d9030e79888d1d5828730b254fedc53c7b640c1")
]

# Bash recipe for building across all platforms
script = raw"""
apk add protoc

cd $WORKSPACE/srcdir
wget https://github.com/Kitware/CMake/releases/download/v3.22.1/cmake-3.22.1-linux-x86_64.sh
chmod u+x cmake-3.22.1-linux-x86_64.sh 
./cmake-3.22.1-linux-x86_64.sh --skip-license --include-subdir
cd onnxruntime/
if [[ $target == aarch64* ]]; then
    CROSS_COMPILE_ARGS="--arm64"
fi
./build.sh \
    --cmake_path /workspace/srcdir/cmake-3.22.1-linux-x86_64/bin/cmake
    --cmake_extra_defines \
        CMAKE_INSTALL_PREFIX=$prefix \
        CMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    --path_to_protoc_exe /usr/bin/protoc
    --config Release \
    --update \
    --build \
    --skip_tests \
    $CROSS_COMPILE_ARGS
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("aarch64", "linux"; libc = "glibc"),
#    Platform("x86_64", "linux"; libc = "glibc")
]


# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("protoc_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"8",
    julia_compat="1.6")
