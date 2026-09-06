version = v"3.16.1"

sources = [
    GitSource("https://github.com/protocolbuffers/protobuf.git", "791a4355c365bd92720160671a7491be168055cb"),
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

additional_include_symbols = Dict{Symbol,String}()
additional_library_symbols = Dict{Symbol,String}()
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
        ExecutableProduct("$binary_symbol", binary_symbol) for binary_symbol in binary_symbols
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
        ExecutableProduct("$binary_symbol", binary_symbol) for binary_symbol in binary_symbols
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

# Avoid problems with `-march`, `-ffast-math` etc.
sed -i -e 's!set(CMAKE_C_COMPILER.*!set(CMAKE_C_COMPILER '${WORKSPACE}/srcdir/files/ccsafe')!' ${CMAKE_TARGET_TOOLCHAIN}
sed -i -e 's!set(CMAKE_CXX_COMPILER.*!set(CMAKE_CXX_COMPILER '${WORKSPACE}/srcdir/files/c++safe')!' ${CMAKE_TARGET_TOOLCHAIN}

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
        -Dprotobuf_BUILD_PROTOC_BINARIES=ON
    )
else
    cmake_extra_args+=(
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
    )
else
    cmake_extra_args+=(
        -Dprotobuf_INSTALL_SDK=OFF
    )
fi

cmake \
    -B work \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=14 \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=$CMAKE_TARGET_TOOLCHAIN \
    -Dprotobuf_BUILD_TESTS=OFF \
    ${cmake_extra_args[@]} \
    cmake
cmake --build work --parallel $nproc
cmake --install work
install_license LICENSE
"""

platforms = expand_cxxstring_abis(supported_platforms())

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("Zlib_jll"),
]

julia_compat = "1.6"
preferred_gcc_version = v"8"
