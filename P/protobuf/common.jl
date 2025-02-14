version = v"3.16.0"

sources = [
    GitSource("https://github.com/protocolbuffers/protobuf.git", "2dc747c574b68a808ea4699d26942c8132fe2b09"),
    DirectorySource(joinpath(@__DIR__, "bundled")),
]

script = raw"""
cd $WORKSPACE/srcdir/protobuf

# Avoid problems with `-march`, `-ffast-math` etc.
sed -i -e 's!set(CMAKE_C_COMPILER.*!set(CMAKE_C_COMPILER '${WORKSPACE}/srcdir/files/ccsafe')!' ${CMAKE_TARGET_TOOLCHAIN}
sed -i -e 's!set(CMAKE_CXX_COMPILER.*!set(CMAKE_CXX_COMPILER '${WORKSPACE}/srcdir/files/c++safe')!' ${CMAKE_TARGET_TOOLCHAIN}

cmake_extra_args=()
if [[ "$BUILD_SHARED_LIBS" == "OFF" ]]; then
    cmake_extra_args+=(
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    )
fi

cmake \
    -B work \
    -G Ninja \
    -DBUILD_SHARED_LIBS=$BUILD_SHARED_LIBS \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=14 \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -Dprotobuf_BUILD_PROTOC_BINARIES=OFF \
    -Dprotobuf_BUILD_TESTS=OFF \
    ${cmake_extra_args[@]} \
    cmake
cmake --build work --parallel ${nproc}
cmake --install work
install_license LICENSE
"""

platforms = expand_cxxstring_abis(supported_platforms())

dependencies = [
    Dependency("Zlib_jll")
]
