# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Aeron"
version = v"1.40.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/real-logic/aeron.git", "1cda80dbcd346ee0409fec5328956292614460df")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
apk update
apk add openjdk11 hdrhistogram-c-dev
echo "unset(CMAKE_C_STANDARD)" >> aeron/CMakeLists.txt
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DAERON_ENABLE_NONSTANDARD_OPTIMIZATIONS=OFF AERON_TESTS=OFF aeron
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    # Platform("i686", "linux"; libc = "musl"),
    # Platform("x86_64", "linux"; libc = "musl"),
    # Platform("aarch64", "linux"; libc = "musl"),
    # Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    # Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("x86_64", "macos"; ),
    Platform("aarch64", "macos"; )
]


# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"11.1.0")
