# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder, Pkg

name = "LAGraph"
version = v"1.2.2"

sources = [
    GitSource(
        "https://github.com/GraphBLAS/LAGraph.git",
        "7543de1f310371c540c23ff5da82705aa4e94ea0";
        tag = "v$(version)",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
# Use CMake_jll instead of the older CMake bundled in the build image.
apk del cmake
cd ${WORKSPACE}/srcdir/LAGraph
install_license LICENSE
CMAKE_FLAGS=()
# Older x86 glibc exposes clock_gettime through librt.
if [[ "${target}" == *86*-linux-gnu ]]; then
    CMAKE_FLAGS+=(-DCMAKE_C_STANDARD_LIBRARIES=-lrt)
fi
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DGraphBLAS_ROOT=${prefix} \
      -DGRAPHBLAS_INCLUDE_DIR=${includedir} \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_TESTING=OFF \
      -DBUILD_STATIC_LIBS=OFF "${CMAKE_FLAGS[@]}"
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("liblagraph", :liblagraph),
    LibraryProduct("liblagraphx", :liblagraphx),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("CMake_jll"), # LAGraph requires CMake >= 3.23.
    Dependency(
        PackageSpec(
            name = "SSGraphBLAS_jll",
            uuid = "7ed9a814-9cab-54e9-8e9e-d9e95b4d61b1",
        );
        # LAGraph requires GraphBLAS >= 10; this JLL is independent of SuiteSparse_jll.
        compat = "10.3.1",
    ),
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else
    Dependency(
        PackageSpec(
            name = "CompilerSupportLibraries_jll",
            uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae",
        );
        compat = "1",
        platforms = filter(!Sys.isbsd, platforms),
    ),
    Dependency(
        PackageSpec(name = "LLVMOpenMP_jll", uuid = "1d63c593-3942-5779-bab2-d838dc0a180e");
        compat = "18.1.8",
        platforms = filter(Sys.isbsd, platforms),
    ),
]

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
    julia_compat = "1.10",
    preferred_gcc_version = v"9",
)

