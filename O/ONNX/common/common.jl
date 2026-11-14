include(joinpath(@__DIR__, "..", "..", "..", "platforms", "macos_sdks.jl"))

version = v"1.23.2"

sources = [
    GitSource("https://github.com/onnx/onnx.git", "e1ac8e74b620bbdc7ba07f0440806bd93f651a28"; tag="v$(version)"),
    DirectorySource(joinpath(@__DIR__, "bundled")),
]

script = raw"""
cd onnx

# Fall back to a stream when floating-point std::to_chars is unavailable
# (libc++ on macOS < 13.3)
atomic_patch -p1 ../patches/printer-to_chars-fallback.patch

# MinGW headers are lowercase, and our cross-compilers run on a case-sensitive filesystem
sed -i 's/#include <Windows.h>/#include <windows.h>/' onnx/checker.cc
# msvcrt.dll (which our MinGW toolchain links against) does not export _strtof_l
atomic_patch -p1 ../patches/mingw-msvcrt-strtof_l.patch

cmake_args=()
if [[ "$BB_RECIPE_NAME" == ONNX ]]; then
    cmake_args+=("-DBUILD_SHARED_LIBS=ON")
elif [[ "$BB_RECIPE_NAME" == ONNX_static ]]; then
    cmake_args+=("-DBUILD_SHARED_LIBS=OFF")
else
    echo "Unknown BB_RECIPE_NAME: $BB_RECIPE_NAME"
    exit 1
fi

# ONNX needs CMake >= 3.26, newer than the one in the rootfs
cmake=${host_bindir}/cmake

${cmake} \
    -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=$CMAKE_TARGET_TOOLCHAIN \
    -DONNX_BUILD_PYTHON=OFF \
    -DONNX_BUILD_TESTS=OFF \
    -DONNX_USE_LITE_PROTO=ON \
    -DONNX_USE_PROTOBUF_SHARED_LIBS=OFF \
    -DProtobuf_PROTOC_EXECUTABLE=$host_bindir/protoc \
    -DPython_EXECUTABLE=$(which python3) \
    ${cmake_args[@]}
${cmake} --build build --parallel $nproc
${cmake} --install build
install_license LICENSE
"""

# std::optional::value needs macOS 10.14 and std::filesystem needs macOS 10.15
sources, script = require_macos_sdk("10.15", sources, script)

platforms = expand_cxxstring_abis(supported_platforms())

products_map = Dict(
    "ONNX" => [
        LibraryProduct("libonnx", :libonnx),
        LibraryProduct("libonnx_proto", :libonnx_proto),
    ],
    "ONNX_static" => [
        FileProduct("lib/libonnx.a", :libonnx),
        FileProduct("lib/libonnx_proto.a", :libonnx_proto),
    ],
)

shared_dependencies = [
    # ONNX >= 1.23 needs CMake >= 3.26
    HostBuildDependency(PackageSpec(name="CMake_jll", version="3.31.9")),
    BuildDependency(PackageSpec(name="ProtocolBuffersSDK_static_jll", version="3.16.1")),
    HostBuildDependency(PackageSpec(name="ProtocolBuffersCompiler_jll", version="3.16.1")),
]

dependencies_map = Dict(
    "ONNX" => [
        shared_dependencies...,
        RuntimeDependency("CompilerSupportLibraries_jll"),
    ],
    "ONNX_static" => shared_dependencies,
)

julia_compat = "1.6"
# ONNX requires C++17, including floating-point std::to_chars (libstdc++ >= 11)
preferred_gcc_version = v"11"
