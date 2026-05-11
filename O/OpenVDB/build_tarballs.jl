# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "OpenVDB"
version = v"13.0.0"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/AcademySoftwareFoundation/openvdb",
        "7c03e1f084873cd1b3422c7ff7aec6ee681b3b38",  # tag v13.0.0
    ),
]

# Bash recipe for building across all platforms
script = raw"""
# OpenVDB 13 needs CMake >= 3.24; the base image ships 3.21.
apk del cmake

cd $WORKSPACE/srcdir/openvdb

args=(
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DCMAKE_CXX_STANDARD=17
    -DOPENVDB_BUILD_BINARIES=OFF
    -DOPENVDB_BUILD_UNITTESTS=OFF
    -DOPENVDB_BUILD_PYTHON_MODULE=OFF
    -DOPENVDB_BUILD_HOUDINI_PLUGIN=OFF
    -DOPENVDB_BUILD_MAYA_PLUGIN=OFF
    -DOPENVDB_BUILD_AX=OFF
    -DOPENVDB_BUILD_NANOVDB=OFF
    -DOPENVDB_CORE_SHARED=ON
    -DOPENVDB_CORE_STATIC=OFF
    -DUSE_EXR=OFF
)
if [[ ${target} == *darwin* ]]; then
   args+=(-DCMAKE_STRIP=${target}-strip)
fi

# boost_jll's mingw tarball installs BoostConfig.cmake under bin/cmake/
# (Windows-native layout) rather than lib/cmake/ where CMake's config-mode
# find_package looks. Point Boost_DIR at the actual location; the glob
# keeps this robust to boost_jll version bumps.
if [[ ${target} == *-mingw32* ]]; then
    args+=(-DBoost_DIR=$(dirname $(ls ${prefix}/bin/cmake/Boost-*/BoostConfig.cmake | head -1)))
fi

cmake -B build -G Ninja "${args[@]}"
# OpenVDB template instantiations are memory-heavy at compile time;
# cap parallelism to keep peak RSS bounded.
cmake --build build --parallel 2
cmake --install build
install_license LICENSE
"""

sources, script = require_macos_sdk("10.14", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# Disable platforms that we don't have oneTBB for
filter!(p -> arch(p) ∉ ("armv6l", "armv7l"), platforms)
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libopenvdb", :libopenvdb),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # OpenVDB 13's CMakeLists requires CMake >= 3.24.
    HostBuildDependency("CMake_jll"),
    Dependency("boost_jll"),
    Dependency("oneTBB_jll"),
    Dependency("Blosc_jll"),
    Dependency("Zlib_jll"),
    # libopenvdb.so links libgcc_s; audit fails to auto-map without this.
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# OpenVDB 13's OpenVDBCXX.cmake requires g++ >= 11.2.1; pick the highest
# bootstrap available in BB (13.2.0).
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"13")
