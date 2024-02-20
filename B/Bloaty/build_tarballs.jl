# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Bloaty"
version_string = "1.1"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/google/bloaty/releases/download/v$(version_string)/bloaty-$(version_string).tar.bz2",
                  "a308d8369d5812aba45982e55e7c3db2ea4780b7496a5455792fb3dcba9abd6f"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/bloaty*/
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -G Ninja \
    `# Encourage CMake to find re2` \
    -DRE2_FOUND=TRUE \
    -DRE2_LIBRARIES='re2' \
    ..
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; exclude=Sys.iswindows))

# The products that we will ensure are always built
products = [
    ExecutableProduct("bloaty", :bloaty)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Capstone_jll"),
    Dependency("protoc_jll"),
    Dependency("RE2_jll"),
    Dependency("Zlib_jll"),
    HostBuildDependency("protoc_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8")
