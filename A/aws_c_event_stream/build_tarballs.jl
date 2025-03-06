# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "aws_c_event_stream"
version = v"0.5.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/awslabs/aws-c-event-stream.git", "9312b052583183b98526aaeb91e5c72ec3db9627"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/aws-c-event-stream
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
    LibraryProduct("libaws-c-event-stream", :libaws_c_event_stream),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("aws_c_common_jll"; compat="0.11.1"),
    Dependency("aws_c_io_jll"; compat="0.17.0"),
    Dependency("aws_checksums_jll"; compat="0.2.3"),
    BuildDependency("aws_lc_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
