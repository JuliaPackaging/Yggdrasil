# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "protoc"
version = v"3.16.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/protocolbuffers/protobuf.git", "2dc747c574b68a808ea4699d26942c8132fe2b09"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/protobuf

# Avoid problems with `-march`, `-ffast-math` etc.
sed -i -e 's!set(CMAKE_C_COMPILER.*!set(CMAKE_C_COMPILER '${WORKSPACE}/srcdir/files/ccsafe')!' ${CMAKE_TARGET_TOOLCHAIN}
sed -i -e 's!set(CMAKE_CXX_COMPILER.*!set(CMAKE_CXX_COMPILER '${WORKSPACE}/srcdir/files/c++safe')!' ${CMAKE_TARGET_TOOLCHAIN}

# Build static libraries
cmake -B work -G Ninja \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=14 \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -Dprotobuf_BUILD_LIBPROTOC=ON \
    -Dprotobuf_BUILD_TESTS=OFF \
    cmake
cmake --build work --parallel ${nproc}
cmake --install work
rm -rf work

# Build dynamic libraries
cmake -B work -G Ninja \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=14 \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -Dprotobuf_BUILD_LIBPROTOC=ON \
    -Dprotobuf_BUILD_TESTS=OFF \
    cmake
cmake --build work --parallel ${nproc}
cmake --install work
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    FileProduct("lib/libprotobuf.a", :libprotobuf_static),
    FileProduct("lib/libprotobuf-lite.a", :libprotobuf_lite_static),
    FileProduct("lib/libprotoc.a", :libprotoc_static),
    LibraryProduct("libprotobuf", :libprotobuf),
    LibraryProduct("libprotobuf-lite", :libprotobuf_lite),
    LibraryProduct("libprotoc", :libprotoc),
    ExecutableProduct("protoc", :protoc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"9")

# Build trigger: 1
