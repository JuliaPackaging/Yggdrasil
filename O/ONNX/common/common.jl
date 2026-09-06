version = v"1.10.2"

sources = [
    GitSource("https://github.com/onnx/onnx.git", "da889e6b95750350726d149bf447bf0cd1245964"),
    DirectorySource(joinpath(@__DIR__, "bundled")),
]

script = raw"""
cd onnx

atomic_patch -p1 ../patches/onnx-onnxifi_dummy.patch
atomic_patch -p1 ../patches/onnx-mingw32.patch
atomic_patch -p1 ../patches/onnx-mingw32-linking.patch

cmake_args=()
if [[ "$BB_RECIPE_NAME" == ONNX ]]; then
    cmake_args+=("-DBUILD_SHARED_LIBS=ON")
elif [[ "$BB_RECIPE_NAME" == ONNX_static ]]; then
    cmake_args+=("-DBUILD_SHARED_LIBS=OFF")
else
    echo "Unknown BB_RECIPE_NAME: $BB_RECIPE_NAME"
    exit 1
fi

cmake \
    -B build \
    -DBUILD_ONNX_PYTHON=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=$CMAKE_TARGET_TOOLCHAIN \
    -DONNX_USE_LITE_PROTO=ON \
    -DONNX_USE_PROTOBUF_SHARED_LIBS=OFF \
    -DProtobuf_PROTOC_EXECUTABLE=$host_bindir/protoc \
    -DPYTHON_EXECUTABLE=$(which python3) \
    ${cmake_args[@]}
cmake --build build --parallel $nproc
cmake --install build
"""

platforms = expand_cxxstring_abis(supported_platforms())

shared_products = [
    LibraryProduct("libonnxifi", :libonnxifi),
    LibraryProduct("libonnxifi_dummy", :libonnxifi_dummy),
    FileProduct("lib/libonnxifi_loader.a", :libonnxifi_loader),
]

products_map = Dict(
    "ONNX" => [
        LibraryProduct("libonnx", :libonnx),
        LibraryProduct("libonnx_proto", :libonnx_proto),
        shared_products...,
    ],
    "ONNX_static" => [
        FileProduct("lib/libonnx.a", :libonnx),
        FileProduct("lib/libonnx_proto.a", :libonnx_proto),
        shared_products...,
    ],
)

shared_dependencies = [
    BuildDependency(PackageSpec(name="ProtocolBuffersSDK_static_jll", version="3.16.0")),
    HostBuildDependency(PackageSpec(name="ProtocolBuffersCompiler_jll", version="3.16.0")),
]

dependencies_map = Dict(
    "ONNX" => [
        shared_dependencies...,
        RuntimeDependency("CompilerSupportLibraries_jll"),
    ],
    "ONNX_static" => shared_dependencies,
)

julia_compat = "1.6"
preferred_gcc_version = v"6"
