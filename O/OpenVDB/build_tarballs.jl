# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OpenVDB"
version = v"13.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource(
        "https://github.com/AcademySoftwareFoundation/openvdb/archive/refs/tags/v$(version).tar.gz",
        "4d6a91df5f347017496fe8d22c3dbb7c4b5d7289499d4eb4d53dd2c75bb454e1",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/openvdb-*/

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

cmake -B build -G Ninja "${args[@]}"
cmake --build build --parallel ${nproc}
cmake --install build
install_license LICENSE
"""

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
    Dependency("boost_jll"; compat="1.85"),
    Dependency("oneTBB_jll"),
    Dependency("Blosc_jll"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# OpenVDB needs C++17, so use a gcc that supports it on every host.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"10")
