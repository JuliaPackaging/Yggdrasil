# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "onnxruntime"
version = v"1.10.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/microsoft/onnxruntime.git", "0d9030e79888d1d5828730b254fedc53c7b640c1")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

wget https://github.com/Kitware/CMake/releases/download/v3.22.1/cmake-3.22.1-linux-x86_64.sh
chmod u+x cmake-3.22.1-linux-x86_64.sh 
./cmake-3.22.1-linux-x86_64.sh --skip-license --include-subdir
CMAKE=`pwd`/cmake-3.22.1-linux-x86_64/bin/cmake

wget https://github.com/protocolbuffers/protobuf/releases/download/v3.16.1/protoc-3.16.1-linux-x86_64.zip
unzip -d protoc protoc-3.16.1-linux-x86_64.zip

cd onnxruntime/

git submodule update --init --recursive

mkdir -p build
cd build
$CMAKE $WORKSPACE/srcdir/onnxruntime/cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DONNX_CUSTOM_PROTOC_EXECUTABLE=$WORKSPACE/srcdir/protoc/bin/protoc \
    -Donnxruntime_BUILD_SHARED_LIB=ON \
    -Donnxruntime_BUILD_UNIT_TESTS=OFF
make -j $nproc
make install
install_license $WORKSPACE/srcdir/onnxruntime/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("aarch64", "linux"; libc = "glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "linux"; libc = "glibc", cxxstring_abi="cxx11")
]


# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"8",
    julia_compat="1.6")
