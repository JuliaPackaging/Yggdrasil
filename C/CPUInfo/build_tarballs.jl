# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CPUInfo"
version = v"0.0.20250626"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/pytorch/cpuinfo.git", "e4cadd02a8b386c38b84f0a19eddacec3f433baa"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cpuinfo

cmake_args=(
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DCPUINFO_BUILD_BENCHMARKS=OFF
    -DCPUINFO_BUILD_MOCK_TESTS=OFF
    -DCPUINFO_BUILD_UNIT_TESTS=OFF
    -DCPUINFO_LIBRARY_TYPE=shared
)

if [[ $target == aarch64-apple-darwin* ]]; then
    cmake_args+=(-DCMAKE_OSX_ARCHITECTURES=arm64)
fi

cmake -B build ${cmake_args[@]}
cmake --build build --parallel ${nproc}
cmake --install build

if [[ $target == *-w64-mingw32 ]]; then
    install -Dvm 755 build/libcpuinfo.dll "${libdir}/libcpuinfo.dll"
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# PPC is not supported
filter!(p -> arch(p) != "powerpc64le", platforms)

# ARM on FreeBSD is not supported
filter!(p -> !(arch(p) == "aarch64" && Sys.isfreebsd(p)), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcpuinfo", :libcpuinfo),
    ExecutableProduct("isa-info", :isa_info),
    ExecutableProduct("cpu-info", :cpu_info),
    ExecutableProduct("cache-info", :cache_info),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
