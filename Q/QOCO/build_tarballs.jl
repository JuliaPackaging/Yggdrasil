# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "QOCO"
version = v"0.3.2"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/qoco-org/qoco.git",
        "598de4e1aeaa9c522b3bc5bb1a56f3d7287dc14f",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd qoco

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DQOCO_BUILD_TYPE=Release \
    -DQOCO_ALGEBRA_BACKEND=builtin \
    -DENABLE_TESTING=OFF \
    -DBUILD_QOCO_DEMO=OFF \
    -DBUILD_QOCO_BENCHMARK_RUNNER=OFF \
    -DCMAKE_C_STANDARD=99

cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = filter!(!Sys.isfreebsd, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libqoco", :qoco),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    julia_compat = "1.6",
)