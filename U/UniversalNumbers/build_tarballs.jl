# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# A newer macOS SDK is required for libc++'s C++20 <concepts> header.
include(joinpath("..", "..", "platforms", "macos_sdks.jl"))

name = "UniversalNumbers"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/jamesquinlan/UniversalNumbers.jl.git",
              "07adfefb0bb7fdb83b16da56f487bd88e5b768ac"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/UniversalNumbers.jl
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
cmake --build build --parallel ${nproc}
cmake --install build

# The compiled library includes both the wrapper (MIT) and the vendored
# Stillwater Universal headers (MIT); ship both licenses.
install_license LICENSE
install_license deps/universal/LICENSE
"""

sources, script = require_macos_sdk("14.0", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> arch(p) ∉ ("i686", "armv6l", "armv7l"), platforms)  # dd uses __uint128_t (64-bit only)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libuniversal", :libuniversal),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.9", preferred_gcc_version=v"13")
