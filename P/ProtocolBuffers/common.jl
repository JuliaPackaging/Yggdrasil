"""
ProtocolBuffers versioning is a little complex: Since May, 2022, with the
release of v21.0, each language runtime, e.g. the C++ runtime  `libprotobuf`,
has its own major version, while the minor version and patch version
respectively match the major version, and the minor version of the
ProtocolBuffers project (and the `protoc` compiler).
E.g., C++ runtime `libprotobuf` v"3.21.0" released with ProtocolBuffers v"21.0"
matches `protoc` v"21.0".

The `protoc` compiler (and `libprotoc`) depends on the C++ runtime `libprotobuf`,
i.e. `protoc` v"21.0" requires C++ runtime `libprotobuf` v"3.21.0".

Specific to the C++ runtime, in contrast to the other ProtocolBuffers
language runtimes, there is no cross-version runtime support, i.e., C++ code
generated with the `protoc` compiler v"21.0" requires C++ runtime
`libprotobuf` v"3.21.0". Additionally, the C++ runtime makes no guarantees
about ABI stability across any releases (major, minor, or patch).

Finally, v"16" releases since v"16.2" has also adopted the May, 2022 versioning
scheme, i.e. `libprotobuf` v"3.16.2" matches `protoc` v"16.2". The same is true
for v"18" since v"18.3", v"19" since v"19.5", and v"20" since v"20.2".

References:
* https://protobuf.dev/support/version-support/
* https://protobuf.dev/support/cross-version-runtime-guarantee/#cpp
* https://protobuf.dev/news/2022-05-06/#versioning
* https://github.com/protocolbuffers/protobuf/blob/v21.0/version.json
"""
base_version = v"22.0" # Cf. https://github.com/protocolbuffers/protobuf/blob/v22.0/version.json

sources = [
    GitSource("https://github.com/protocolbuffers/protobuf.git", "a847a8dc4ba1d99e7ba917146c84438b4de7d085"),
    DirectorySource(joinpath(@__DIR__, "bundled")),
]

script = raw"""
cd $WORKSPACE/srcdir/protobuf

# This patch stems from upstream: https://github.com/protocolbuffers/protobuf/pull/12043
atomic_patch -p1 ../patches/aarch64.patch

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
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=$CMAKE_TARGET_TOOLCHAIN \
    -Dprotobuf_ABSL_PROVIDER=package \
    -Dprotobuf_BUILD_TESTS=OFF \
    ${cmake_extra_args[@]}
cmake --build build --parallel $nproc
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
    Dependency("Zlib_jll"),
]

julia_compat = "1.6"
preferred_gcc_version = v"8" # GCC >= 7.3 required: https://github.com/protocolbuffers/protobuf/blob/v22.0/src/google/protobuf/port_def.inc#L196
