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

The JLLs are versioned as follows:
* `ProtocolBuffersCompiler` uses the ProtocolBuffers project (and `protoc`) version,
  e.g. v"36.2".
* `ProtocolBuffers`, `ProtocolBuffersLite`, `ProtocolBuffersSDK`, and
  `ProtocolBuffersSDK_static` use the C++ runtime version, e.g. v"7.36.2".

References:
* https://protobuf.dev/support/version-support/
* https://protobuf.dev/support/cross-version-runtime-guarantee/#cpp
* https://protobuf.dev/news/2022-05-06/#versioning
* https://github.com/protocolbuffers/protobuf/blob/v21.0/version.json
"""
base_version = v"36.2"
# The C++ runtime major version can not be derived from `base_version`, cf. "cpp" in
# https://github.com/protocolbuffers/protobuf/blob/v36.2/version.json
cpp_library_major_version = 7
cpp_library_version = VersionNumber(cpp_library_major_version, base_version.major, base_version.minor)

# protobuf v36.2 is tested with abseil-cpp 20250512.1 (cf. `cmake/dependencies.cmake`), and
# builds with the newer abseil-cpp LTS available as a JLL. abseil-cpp makes no ABI guarantees
# across LTS releases (its symbols live in an `lts_YYYYMMDD` inline namespace), so the LTS is
# pinned - also for consumers of the static libraries in ProtocolBuffersSDK_static.
abseil_cpp_compat = "20250814.1"

include(joinpath(@__DIR__, "..", "..", "..", "platforms", "macos_sdks.jl"))

sources = [
    GitSource("https://github.com/protocolbuffers/protobuf.git", "2c74169b34066ceb8ddb6b882fcb3fb32d737a55"),
    DirectorySource(joinpath(@__DIR__, "bundled")),
]

binary_symbols = Dict(
    :protoc => "protoc",
)
# The upb code generators are built and installed alongside `protoc` (libprotoc requires libupb)
upb_binary_symbols = Dict(
    :protoc_gen_upb => "protoc-gen-upb",
    :protoc_gen_upbdefs => "protoc-gen-upbdefs",
    :protoc_gen_upb_minitable => "protoc-gen-upb_minitable",
)
all_binary_symbols = merge(binary_symbols, upb_binary_symbols)

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

# `protobuf` includes https://github.com/protocolbuffers/utf8_range (always built as static
# libraries, cf. `utf8_range-static.patch`), and upb (`libupb` is always a static library).
additional_include_symbols = Dict(
    :utf8_range_h => "utf8_range.h",
    :utf8_validity_h => "utf8_validity.h",
)
additional_library_symbols = Dict(
    :libutf8_range => "utf8_range",
    :libutf8_validity => "utf8_validity",
    :libupb => "upb",
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
        ExecutableProduct(name, symbol) for (symbol, name) in all_binary_symbols
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
        ExecutableProduct(name, symbol) for (symbol, name) in all_binary_symbols
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

# Adds options for installing only parts of protobuf (libprotobuf, libprotobuf-lite, or the SDK)
atomic_patch -p1 ../patches/protobuf-cmake-install-components.patch
# Embeds utf8_range in the protobuf libraries rather than building separate shared libraries
atomic_patch -p1 ../patches/utf8_range-static.patch
# Fixes FreeBSD build (`isascii` undeclared in libc++'s <locale>); backported from upstream main
atomic_patch -p1 ../patches/freebsd-posix-c-source.patch

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
    # libprotoc requires libupb
    cmake_extra_args+=(
        -Dprotobuf_BUILD_PROTOC_BINARIES=ON
        -Dprotobuf_BUILD_LIBUPB=ON
    )
elif [[ "$BB_PROTOBUF_PRODUCT" == ProtocolBuffersLite ]]; then
    cmake_extra_args+=(
        -Dprotobuf_BUILD_PROTOC_BINARIES=OFF
        -Dprotobuf_BUILD_LIBPROTOBUF=OFF
        -Dprotobuf_BUILD_LIBUPB=OFF
    )
else
    cmake_extra_args+=(
        -Dprotobuf_BUILD_PROTOC_BINARIES=OFF
        -Dprotobuf_BUILD_LIBUPB=OFF
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

cmake \
    -B build \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_FIND_ROOT_PATH=$prefix \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=$CMAKE_TARGET_TOOLCHAIN \
    -Dprotobuf_BUILD_TESTS=OFF \
    -Dprotobuf_LOCAL_DEPENDENCIES_ONLY=ON \
    ${cmake_extra_args[@]}
cmake --build build --parallel $nproc
cmake --install build
# Make the pkg-config files relocatable (libdir and includedir are absolute paths)
for pc in ${prefix}/lib/pkgconfig/{protobuf,protobuf-lite,upb,utf8_range}.pc; do
    if [[ -f "${pc}" ]]; then
        sed -i -e "s!=${prefix}/!=\${prefix}/!" "${pc}"
    fi
done
install_license LICENSE
"""

# abseil-cpp in C++17 mode requires a newer libc++ and deployment target than the default
# Intel macOS SDK provides (same as for abseil_cpp_jll)
sources, script = require_macos_sdk("10.14", sources, script)

platforms = expand_cxxstring_abis(supported_platforms())

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("abseil_cpp_jll"; compat=abseil_cpp_compat),
    Dependency("Zlib_jll"),
]

julia_compat = "1.6"
# protobuf requires C++17; abseil-cpp headers include <filesystem>, which GCC 7 and 8 do not ship
preferred_gcc_version = v"9"
