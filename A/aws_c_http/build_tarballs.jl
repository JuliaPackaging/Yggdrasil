# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "aws_c_http"
version = v"0.8.8"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/awslabs/aws-c-http.git", "4e74ab1e3702763e0b87bd1752f5a37c2f0400ac"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/aws-c-http

# Patch for MinGW toolchain
find . -type f -exec sed -i 's/WS2tcpip.h/ws2tcpip.h/g' '{}' \;

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_TESTING=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    ..
cmake --build . -j${nproc} --target install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libaws-c-http", :libaws_c_http),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("aws_c_compression_jll"; compat="0.2.17"),
    Dependency("aws_c_io_jll"; compat="0.14.11"),
    BuildDependency("aws_lc_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
