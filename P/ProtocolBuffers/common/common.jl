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
base_version = v"22.0"
# Cf. https://github.com/protocolbuffers/protobuf/blob/v22.0/version.json
cpp_library_version = VersionNumber(4, base_version.major, base_version.minor)

sources = [
    GitSource("https://github.com/protocolbuffers/protobuf.git", "a847a8dc4ba1d99e7ba917146c84438b4de7d085"),
    DirectorySource(joinpath(@__DIR__, "bundled")),
]

binary_symbols = [:protoc]

include_symbols = Dict{Symbol,String}()

protobuf_library_symbols = Dict(
    :libprotobuf => "protobuf",
)
protobuf_lite_library_symbols = Dict(
    :libprotobuf_lite => "protobuf-lite",
)
protoc_library_symbols = Dict(
    :libprotoc => "protoc",
)
library_symbols = merge(protobuf_library_symbols, protobuf_lite_library_symbols)

# `protobuf` includes https://github.com/protocolbuffers/utf8_range
additional_include_symbols = Dict(
    :utf8_range_h => "utf8_range.h",
    :utf8_validity_h => "utf8_validity.h",
)
additional_library_symbols = Dict(
    :libutf8_range => "utf8_range",
    :libutf8_validity => "utf8_validity",
)
all_include_symbols = merge(include_symbols, additional_include_symbols)
all_library_symbols = merge(library_symbols, additional_library_symbols)

products_map = Dict{String, Vector{Product}}(
    "ProtocolBuffers" => [
        LibraryProduct("lib$name", symbol) for (symbol, name) in protobuf_library_symbols
    ],
    "ProtocolBuffersLite" => [
        LibraryProduct("lib$name", symbol) for (symbol, name) in protobuf_lite_library_symbols
    ],
)
products_map["ProtocolBuffersCompiler"] = vcat(
    products_map["ProtocolBuffers"],
    [
        LibraryProduct("lib$name", symbol) for (symbol, name) in protoc_library_symbols
    ], [
        ExecutableProduct("$binary_symbol", :binary_symbol) for binary_symbol in binary_symbols
    ]
)
products_map["ProtocolBuffersSDK"] = vcat(
    products_map["ProtocolBuffersCompiler"],
    products_map["ProtocolBuffersLite"],
    [
        FileProduct("include/$name", symbol) for (symbol, name) in all_include_symbols
    ],[
        FileProduct("lib/lib$name.a", symbol) for (symbol, name) in additional_library_symbols
    ],[
        FileProduct("lib/pkgconfig/$name.pc", Symbol(symbol, :_pkgconfig)) for (symbol, name) in library_symbols
    ]
)
products_map["ProtocolBuffersSDK_static"] = vcat(
    [
        ExecutableProduct("$binary_symbol", :binary_symbol) for binary_symbol in binary_symbols
    ],
    [
        FileProduct("include/$name", symbol) for (symbol, name) in all_include_symbols
    ],[
        FileProduct("lib/lib$name.a", symbol) for (symbol, name) in merge(all_library_symbols, protoc_library_symbols)
    ],[
        FileProduct("lib/pkgconfig/$name.pc", Symbol(symbol, :_pkgconfig)) for (symbol, name) in library_symbols
    ]
)

script = raw"""
cd $WORKSPACE/srcdir/protobuf

# This patch stems from upstream: https://github.com/protocolbuffers/protobuf/pull/12043
atomic_patch -p1 ../patches/aarch64.patch

atomic_patch -p1 ../patches/protobuf-cmake-install-components.patch

cmake_extra_args=()

if [[ "$BB_PROTOBUF_PRODUCT" == ProtocolBuffersSDK_static ]]; then
    cmake_extra_args+=(
        -DBUILD_SHARED_LIBS=OFF
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    )
else
    cmake_extra_args+=(
        -DBUILD_SHARED_LIBS=ON
    )
fi

if [[ "$BB_PROTOBUF_PRODUCT" == ProtocolBuffersCompiler ]] || [[ "$BB_PROTOBUF_PRODUCT" == ProtocolBuffersSDK* ]]; then
    cmake_extra_args+=(
        -Dprotobuf_BUILD_PROTOBUF_BINARIES=ON
        -Dprotobuf_BUILD_PROTOC_BINARIES=ON
    )
else
    cmake_extra_args+=(
        -Dprotobuf_BUILD_PROTOBUF_BINARIES=ON
        -Dprotobuf_BUILD_PROTOC_BINARIES=OFF
    )
fi

if [[ "$BB_PROTOBUF_PRODUCT" == ProtocolBuffers ]]; then
    cmake_extra_args+=(
        -Dprotobuf_INSTALL_PROTOBUF=ON
    )
else
    cmake_extra_args+=(
        -Dprotobuf_INSTALL_PROTOBUF=OFF
    )
fi

if [[ "$BB_PROTOBUF_PRODUCT" == ProtocolBuffersLite ]]; then
    cmake_extra_args+=(
        -Dprotobuf_INSTALL_PROTOBUF_LITE=ON
    )
else
    cmake_extra_args+=(
        -Dprotobuf_INSTALL_PROTOBUF_LITE=OFF
    )
fi

if [[ "$BB_PROTOBUF_PRODUCT" == ProtocolBuffersSDK* ]]; then
    cmake_extra_args+=(
        -Dprotobuf_INSTALL_SDK=ON
        -Dutf8_range_ENABLE_INSTALL=ON
    )
else
    cmake_extra_args+=(
        -Dprotobuf_INSTALL_SDK=OFF
        -Dutf8_range_ENABLE_INSTALL=OFF
    )
fi

git submodule update --init --recursive --depth 1 third_party/jsoncpp
cmake \
    -B build \
    -G Ninja \
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

dependencies = [
    Dependency("abseil_cpp_jll"; compat="20230125.0"),
    Dependency("Zlib_jll"),
]

julia_compat = "1.6"
preferred_gcc_version = v"8" # GCC >= 7.3 required: https://github.com/protocolbuffers/protobuf/blob/v22.0/src/google/protobuf/port_def.inc#L196
