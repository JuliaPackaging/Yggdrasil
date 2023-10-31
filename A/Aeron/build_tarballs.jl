# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Aeron"
version = v"1.42.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/real-logic/aeron.git", "a6484d2796d3bc43241e4cfe48a8306f0094e5fe"),
]

# Bash recipe for building across all platforms
script = raw"""
apk update
apk add openjdk11 hdrhistogram-c-dev libbsd-dev util-linux-dev
cd $WORKSPACE/srcdir/aeron
sed -i '1s;^;add_compile_options("-lrt")\nlink_libraries("-lrt")\n;' CMakeLists.txt
mkdir build && cd build
CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=$prefix
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
-DCMAKE_BUILD_TYPE=Release
-DCMAKE_C_EXTENSIONS=ON
-DBUILD_AERON_DRIVER=ON
-DBUILD_AERON_ARCHIVE_API=OFF
-DAERON_TESTS=OFF
-DAERON_SYSTEM_TESTS=OFF
-DAERON_BUILD_SAMPLES=OFF
-DAERON_BUILD_DOCUMENTATION=OFF
-DAERON_ENABLE_NONSTANDARD_OPTIMIZATIONS=OFF
-DAERON_INSTALL_TARGETS=ON)
cmake .. "${CMAKE_FLAGS[@]}"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    # Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    # Platform("aarch64", "linux"; libc = "glibc"),
    # Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    # Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    # Platform("powerpc64le", "linux"; libc = "glibc"),
    # Platform("i686", "linux"; libc = "musl"),
    # Platform("x86_64", "linux"; libc = "musl"),
    # Platform("aarch64", "linux"; libc = "musl"),
    # Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    # Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    # Platform("x86_64", "macos"; ),
    # Platform("aarch64", "macos"; )
]
# platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = Product[
    LibraryProduct(["libaeron"], :libaeron)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6", preferred_gcc_version = v"11.1.0")
