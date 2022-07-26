# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "gRPC"
version = v"1.36.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/grpc/grpc.git", "3e53dbe8213137d2c731ecd4d88ebd2948941d75")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/grpc
git submodule update --init --recursive
mkdir -p cmake/build
pushd "cmake/build"
cmake \
    -DgRPC_INSTALL=ON \
    -DgRPC_BUILD_TESTS=OFF \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DgRPC_SSL_PROVIDER=package \
    -DgRPC_PROTOBUF_PROVIDER=package \
    -DgRPC_ZLIB_PROVIDER=package \
    ../..
make
make install
popd
mkdir -p cmake/build
pushd "cmake/build"
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DgRPC_BUILD_TESTS=OFF \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DgRPC_PROTOBUF_PROVIDER=package \
    -DgRPC_ZLIB_PROVIDER=package \
    -DABSL_PROPAGATE_CXX_STD=ON \
    ../..
make
make install
popd
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc", libgfortran_version=v"5.0.0"),
    Platform("x86_64", "linux"; libc="musl", libgfortran_version=v"5.0.0")
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("grpc_cpp_plugin", :grpc_cpp_plugin),
    ExecutableProduct("grpc_csharp_plugin", :grpc_csharp_plugin),
    ExecutableProduct("grpc_objective_c_plugin", :grpc_objective_c_plugin),
    ExecutableProduct("grpc_python_plugin", :grpc_python_plugin),
    ExecutableProduct("grpc_ruby_plugin", :grpc_ruby_plugin),
    ExecutableProduct("grpc_node_plugin", :grpc_node_plugin),
    ExecutableProduct("grpc_php_plugin", :grpc_php_plugin)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Zlib_jll"),
    BuildDependency("protoc_jll"),
    BuildDependency("OpenSSL_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
