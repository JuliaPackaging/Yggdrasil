# Protobuf version numbers are weird: The version number across all languages
# only includes the minor and patch release.
# Each language runtime, e.g. the C++ runtime  `libprotobuf`, has its own major
# version on top of that.
# Thus, e.g. ProtocolBuffers, and protoc, v"22.0" matches C++ runtime v"5.22.0".
# 
# Cf. https://github.com/protocolbuffers/protobuf/blob/v22.0/version.json
base_version = v"0.22.0"

sources = [
    GitSource("https://github.com/protocolbuffers/protobuf.git", "a847a8dc4ba1d99e7ba917146c84438b4de7d085"),
]

script = raw"""
cd $WORKSPACE/srcdir/protobuf

cmake_extra_args=()
if [[ "$BB_PROTOBUF_BUILD_SHARED_LIBS" == "OFF" ]]; then
    cmake_extra_args+=(
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    )
fi
if [[ "$BB_PROTOBUF_PRODUCT" == "libprotobuf" ]]; then
    cmake_extra_args+=(
        -Dprotobuf_BUILD_PROTOBUF_BINARIES=ON
        -Dprotobuf_BUILD_PROTOC_BINARIES=OFF
    )
elif [[ "$BB_PROTOBUF_PRODUCT" == "protoc" ]]; then
    cmake_extra_args+=(
        -Dprotobuf_BUILD_PROTOBUF_BINARIES=ON
        -Dprotobuf_BUILD_PROTOC_BINARIES=ON
    )
else
    exit 1
fi

git submodule update --init --recursive --depth 1 third_party/jsoncpp
cmake \
    -B build \
    -G Ninja \
    -DBUILD_SHARED_LIBS=$BB_PROTOBUF_BUILD_SHARED_LIBS \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=14 \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -Dprotobuf_ABSL_PROVIDER=package \
    -Dprotobuf_BUILD_TESTS=OFF \
    "${cmake_extra_args[@]}"
cmake --build build --parallel ${nproc}
cmake --install build
install_license LICENSE
"""

platforms = expand_cxxstring_abis(supported_platforms())

library_symbols = Dict(
    :libprotobuf => "libprotobuf",
    :libprotobuf_lite => "libprotobuf-lite",
)

additional_library_symbols = [
    # `protobuf` includes https://github.com/protocolbuffers/utf8_range
    :libutf8_range,
    :libutf8_validity,
]

dependencies = [
    Dependency("abseil_cpp_jll"; compat="20230125.0"),
]
