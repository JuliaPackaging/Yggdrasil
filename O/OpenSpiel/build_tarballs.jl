# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

julia_version = v"1.7.0"

name = "OpenSpiel"
version = v"1.1.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/deepmind/open_spiel/archive/v1.1.1.tar.gz", "73d46e2d9ce7a86a420aad141b789e98237463b5c98608401faf86b15ec5eaf9"),
    ArchiveSource("https://github.com/findmyway/dds/archive/v0.1.1.tar.gz", "fd13ee77feb5b5c3dfcc3333a0523266beb2a3d27715703cf508313af25306e5"),
    ArchiveSource("https://github.com/abseil/abseil-cpp/archive/20211102.0.tar.gz", "dcf71b9cba8dc0ca9940c4b316a0c796be8fab42b070bb6b7cab62b48f0e66c4"),
    ArchiveSource("https://github.com/findmyway/hanabi-learning-environment/archive/v0.1.0.tar.gz", "6126936fd13a95f8cadeacaa69dfb38a960eaf3bd588aacc8893a6e07e4791a3"),
    ArchiveSource("https://github.com/findmyway/project_acpc_server/archive/v0.1.0.tar.gz", "e29f969dd62ba354b7019cae3f7f1dbfbd9a744687ea4a8f7494c2bb1ee87382"),
]

# Bash recipe for building across all platforms
script = raw"""

mv open_spiel-* open_spiel
mv abseil-cpp-* open_spiel/open_spiel/abseil-cpp
mv dds-* open_spiel/open_spiel/games/bridge/double_dummy_solver
mv hanabi-learning-environment-* open_spiel/open_spiel/games/hanabi/hanabi-learning-environment
mv project_acpc_server-* open_spiel/open_spiel/games/universal_poker/acpc

mkdir open_spiel/build
cd open_spiel/build
export OPEN_SPIEL_BUILD_WITH_JULIA=ON OPEN_SPIEL_BUILD_WITH_PYTHON=OFF OPEN_SPIEL_BUILD_WITH_HANABI=ON OPEN_SPIEL_BUILD_WITH_ACPC=OFF
cmake \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DJulia_PREFIX=${prefix} \
    ../open_spiel/
make -j${nproc}
make install
install_license ${WORKSPACE}/srcdir/open_spiel/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
]
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libspieljl", :libspieljl),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libcxxwrap_julia_jll"),
    BuildDependency(PackageSpec(; name="libjulia_jll", version=julia_version))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"9",
    julia_compat="$(julia_version.major).$(julia_version.minor)"
)
