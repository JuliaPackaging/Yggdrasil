# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ONNX"
version = v"1.10.2"

sources = [
    ArchiveSource(
        "https://github.com/onnx/onnx/archive/refs/tags/v$(version).tar.gz",
        "520b3aa34272cc215e2eb41385f58adf01750d88858d4722563edca8410c5dc9",
    ),
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
    -DProtobuf_PROTOC_EXECUTABLE=${host_bindir}/protoc \
    ..
cmake --build . --config Release --target install -- -j${nproc}
"""

#=
Sadly, no windows support yet. It looks to me like the upstream treats
`defined(_WIN32)` as synonymous with `build with MSVC`.
=#
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true, exclude=Sys.iswindows))

products = [
    FileProduct("lib/libonnx.a", :libonnx),
    LibraryProduct("libonnxifi", :libonnxifi),
    LibraryProduct("libonnxifi_dummy", :libonnxifi_dummy),
]

dependencies = [HostBuildDependency("protoc_jll"), Dependency("protoc_jll")]

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
