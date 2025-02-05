version = v"3.16.0"

sources = [
    GitSource("https://github.com/protocolbuffers/protobuf.git", "2dc747c574b68a808ea4699d26942c8132fe2b09"),
    DirectorySource(joinpath(@__DIR__, "bundled")),
]

binary_symbols = [:protoc]

include_dirs = ["google/protobuf"]

include_symbols = Dict{Symbol,String}()

library_dirs = [
    "cmake/protobuf",
]

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

products_map = Dict(
    "ProtocolBuffers" => [
        LibraryProduct("lib$name", symbol) for (symbol, name) in protobuf_library_symbols
    ],
    "ProtocolBuffersCompiler" => vcat(
        [
            LibraryProduct("lib$name", symbol) for (symbol, name) in protoc_library_symbols
        ], [
            ExecutableProduct("$binary_symbol", :binary_symbol) for binary_symbol in binary_symbols
        ]
    ),
    "ProtocolBuffersLite" => [
        LibraryProduct("lib$name", symbol) for (symbol, name) in protobuf_lite_library_symbols
    ],
    "ProtocolBuffersSDK" => vcat(
        [
            FileProduct("include/$name", symbol) for (symbol, name) in all_include_symbols
        ],[
            FileProduct("lib/lib$name.a", symbol) for (symbol, name) in additional_library_symbols
        ],[
            FileProduct("lib/pkgconfig/$name.pc", Symbol(symbol, :_pkgconfig)) for (symbol, name) in library_symbols
        ]
    ),
    "ProtocolBuffersSDK_static" => vcat(
        [
            FileProduct("include/$name", symbol) for (symbol, name) in all_include_symbols
        ],[
            FileProduct("lib/lib$name.a", symbol) for (symbol, name) in all_library_symbols
        ],[
            FileProduct("lib/pkgconfig/$name.pc", Symbol(symbol, :_pkgconfig)) for (symbol, name) in library_symbols
        ]
    ),
)

script = """
BB_PROTOBUF_BIN_FILES=($(join(["bin/$bin" for bin in binary_symbols], " ")))
BB_PROTOBUF_INCLUDE_DIRS=($(join(["include/$include_dir" for include_dir in include_dirs], " ")))
BB_PROTOBUF_INCLUDE_FILES=($(join(["include/$include_file" for include_file in values(all_include_symbols)], " ")))
BB_PROTOBUF_LIB_DIRS=($(join(["lib/$library_dir" for library_dir in library_dirs], " ")))
BB_PROTOBUF_LIBRARIES=($(join(values(library_symbols), " ")))
BB_PROTOBUF_ADDITIONAL_LIBRARIES=($(join(values(additional_library_symbols), " ")))
BB_PROTOC_LIBRARIES=($(join(values(protoc_library_symbols), " ")))
""" * raw"""
cd $WORKSPACE/srcdir/protobuf

# Avoid problems with `-march`, `-ffast-math` etc.
sed -i -e 's!set(CMAKE_C_COMPILER.*!set(CMAKE_C_COMPILER '${WORKSPACE}/srcdir/files/ccsafe')!' ${CMAKE_TARGET_TOOLCHAIN}
sed -i -e 's!set(CMAKE_CXX_COMPILER.*!set(CMAKE_CXX_COMPILER '${WORKSPACE}/srcdir/files/c++safe')!' ${CMAKE_TARGET_TOOLCHAIN}

cmake_extra_args=()

if [[ "$BB_PROTOBUF_PRODUCT" == "ProtocolBuffersSDK_static" ]]; then
    cmake_extra_args+=(
        -DBUILD_SHARED_LIBS=OFF
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    )
else
    cmake_extra_args+=(
        -DBUILD_SHARED_LIBS=ON
    )
fi

if [[ "$BB_PROTOBUF_PRODUCT" == "ProtocolBuffersCompiler" ]]; then
    cmake_extra_args+=(
        -Dprotobuf_BUILD_PROTOC_BINARIES=ON
    )
else
    cmake_extra_args+=(
        -Dprotobuf_BUILD_PROTOC_BINARIES=OFF
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

# Ensure the proper files are in $prefix
include_dirs_regex=$(IFS='|' ; echo "${BB_PROTOBUF_INCLUDE_DIRS[*]}")
lib_dirs_regex=$(IFS='|' ; echo "${BB_PROTOBUF_LIB_DIRS[*]}")
lib_ext_regex="(${dlext}.*|.+\.${dlext})"
if [[ "$BB_PROTOBUF_PRODUCT" == "ProtocolBuffersSDK_static" ]]; then
    lib_ext_regex=a
fi

cd $prefix

if [[ "$BB_PROTOBUF_PRODUCT" == "ProtocolBuffersCompiler" ]]; then
    bin_files=($(find bin -type f | sort))
    for bin_file in "${bin_files[@]}"; do
        match_found=false
        for bin_name in "${BB_PROTOBUF_BIN_FILES[@]}"; do
            if [[ "$bin_file" =~ ^${bin_name} ]]; then
                match_found=true
                break
            fi
        done
        if ! $match_found; then
            exit 1
        fi
    done
else
    [[ "$target" == *-w64-mingw32 ]] || [[ ! -d bin ]] || exit 1
fi

include_files=($(find include -type f | grep -E -v "^($include_dirs_regex)/" | sort))
[[ "$(printf "%s\n" ${include_files[@]})" == "$(printf "%s\n" "${BB_PROTOBUF_INCLUDE_FILES[@]}" | sort)" ]] || exit 1

lib_files=($(find lib -type f | grep -E -v "^($lib_dirs_regex)/" | sort))
for lib_file in "${lib_files[@]}"; do
    match_found=false
    for lib_name in "${BB_PROTOBUF_LIBRARIES[@]}"; do
        if $(echo "$lib_file" | grep -q -E "^lib/lib${lib_name}\.${lib_ext_regex}") || [[  "$lib_file" =~ ^lib/pkgconfig/${lib_name}.pc ]]; then
            match_found=true
            break
        fi
    done
    for lib_name in "${BB_PROTOBUF_ADDITIONAL_LIBRARIES[@]}"; do
        if [[ "$lib_file" =~ ^lib/lib${lib_name}.a ]]; then
            match_found=true
            break
        fi
    done
    for lib_name in "${BB_PROTOC_LIBRARIES[@]}"; do
        if $(echo "$lib_file" | grep -q -E "^lib/lib${lib_name}\.${lib_ext_regex}"); then
            match_found=true
            break
        fi
    done
    if ! $match_found; then
        exit 1
    fi
done

# Ensure the proper files are in each tarball
if [[ "$BB_PROTOBUF_PRODUCT" =~ ^ProtocolBuffers(Lite|Compiler)?$ ]]; then
    rm -frv "${BB_PROTOBUF_INCLUDE_DIRS[@]}"
    rm -fv "${BB_PROTOBUF_INCLUDE_FILES[@]}"
    find include -type d | xargs rmdir --ignore-fail-on-non-empty -p

    rm -frv "${BB_PROTOBUF_LIB_DIRS[@]}"
    rm -fv $(for lib_name in "${BB_PROTOBUF_LIBRARIES[@]}"; do echo lib/pkgconfig/${lib_name}.pc; done)
    rm -fv $(for lib_name in "${BB_PROTOBUF_ADDITIONAL_LIBRARIES[@]}"; do echo lib/lib${lib_name}.a; done)
    find lib -type d | xargs rmdir --ignore-fail-on-non-empty -p
elif [[ "$BB_PROTOBUF_PRODUCT" == "ProtocolBuffersSDK" ]]; then
    rm -fv $(for lib_name in "${BB_PROTOBUF_LIBRARIES[@]}"; do echo lib/lib${lib_name}.${dlext}*; done)
fi

if [[ "$BB_PROTOBUF_PRODUCT" == "ProtocolBuffers" ]]; then
    rm -fv lib/libprotobuf-lite.${dlext}*
elif [[ "$BB_PROTOBUF_PRODUCT" == "ProtocolBuffersLite" ]]; then
    rm -fv lib/libprotobuf.${dlext}*
elif [[ "$BB_PROTOBUF_PRODUCT" == "ProtocolBuffersCompiler" ]]; then
    rm -fv $(for lib_name in "${BB_PROTOBUF_LIBRARIES[@]}"; do echo lib/lib${lib_name}.${dlext}*; done)
fi
"""

platforms = expand_cxxstring_abis(supported_platforms())

dependencies = [
    Dependency("Zlib_jll"),
]

julia_compat = "1.6"
preferred_gcc_version = v"8"
