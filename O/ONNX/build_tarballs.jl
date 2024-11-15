# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ONNX"
version = v"1.11.0"

sources = [
    GitSource("https://github.com/onnx/onnx.git", "96046b8ccfb8e6fa82f6b2b34b3d56add2e8849c"),
]

script = raw"""
cd onnx*
mkdir build
cd build
cmake \
    -DBUILD_ONNX_PYTHON=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DONNX_USE_LITE_PROTO=ON \
    -DONNX_USE_PROTOBUF_SHARED_LIBS=ON \
    -DProtobuf_PROTOC_EXECUTABLE=$host_bindir/protoc \
    -DPYTHON_EXECUTABLE=$(which python3) \
    ..
cmake --build . --config Release --target install -- -j${nproc}
"""

platforms = expand_cxxstring_abis(supported_platforms())

products = [
    FileProduct("lib/libonnx.a", :libonnx),
    LibraryProduct("libonnxifi", :libonnxifi),
    LibraryProduct("libonnxifi_dummy", :libonnxifi_dummy),
]

dependencies = [
    HostBuildDependency(PackageSpec(name="protoc_jll", version=v"3.16.1")), # TODO should v3.16.0
    Dependency("protoc_jll", v"3.16.1"), # TODO should v3.16.0
]

build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    preferred_gcc_version = v"9",
    julia_compat = "1.6",
)
