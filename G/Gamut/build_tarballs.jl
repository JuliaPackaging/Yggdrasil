# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "Gamut"
version = v"2.3.1"

# The Gamut core: a C++17 library behind a plain C interface, which the
# GamutFile.jl package calls.
# The 2.3.1 release commit.  The release is tagged only after Gamut_jll is
# registered (GamutFile 2.3.1 depends on it), on a later commit that changes
# dates alone; the core built here is the one the tag carries.
sources = [
    GitSource("https://github.com/bijective-systems-org/gamut.git",
              "7a032250062aa16013d5771d2b3ba72bf3cd4c68"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/gamut

if [[ ${target} == x86_64-linux-musl ]]; then
    # HDF5 needs libcurl, and it needs to be the BinaryBuilder libcurl, not the system libcurl
    rm /usr/lib/libcurl.*
    rm /usr/lib/libnghttp2.*
fi

cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DHDF5_ROOT=${prefix} \
    -DGAMUT_BUILD_TESTS=OFF
cmake --build build --parallel ${nproc}
cmake --install build

install_license LICENSE
"""

# std::filesystem needs macOS 10.15.
sources, script = require_macos_sdk("10.15", sources, script)

# HDF5_jll is built against MPI, so this package is too.
augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
    """

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
platforms, platform_dependencies = MPI.augment_platforms(platforms)

products = [
    LibraryProduct(["libgamut", "gamut"], :libgamut),
]

dependencies = [
    Dependency("HDF5_jll"; compat="2.2.1"),
    Dependency("Zlib_jll"; compat="1.2.12"),
]
append!(dependencies, platform_dependencies)

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and `dlopen`s the shared libraries.
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

# GCC 10 for C++17 with std::filesystem in libstdc++.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.10", preferred_gcc_version=v"10")
