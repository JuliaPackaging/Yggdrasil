# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "spglib"
version = v"2.1.0"

# Collection of sources required to build spglib
sources = [
    GitSource("https://github.com/spglib/spglib.git", "59bea8a7df30c8f2202ed0ee1033be0d98d9ed5e"),
    GitSource("https://github.com/google/googletest.git", "e2239ee6043f73722e7aa812a459f54a28552929"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/googletest
mkdir build && cd build
cmake -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_GMOCK=OFF \
    -DCMAKE_CXX_STANDARD=11 \
    -Wno-dev \
    ..
make -j${nproc}
make install

cd $WORKSPACE/srcdir/spglib
args=""
if [[ ! -z "${CMAKE_TARGET_TOOLCHAIN}" ]]; then
  args="${args} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}"
fi
cmake -B ./build \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DFETCHCONTENT_SOURCE_DIR_GTEST=$(echo ${WORKSPACE}/srcdir/googletest*/) \
      ${args}
cmake --build ./build -j${nproc}
if [[ -z "${CMAKE_TARGET_TOOLCHAIN}" ]]; then
  ctest --test-dir ./build
fi
cmake --install ./build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libsymspg", :libsymspg)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(platform -> !Sys.isbsd(platform) || Sys.isapple(platform), platforms)),
    Dependency("LLVMOpenMP_jll"; platforms=filter(platform -> !Sys.isbsd(platform) || Sys.isapple(platform), platforms)),
    Dependency("GoogleTest_jll"; platforms=filter(platform -> !Sys.isbsd(platform) || Sys.isapple(platform), platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
