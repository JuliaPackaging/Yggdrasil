# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder, Pkg

name = "LAGraph"
version = v"1.0.1"

sources = [
    GitSource(
        "https://github.com/GraphBLAS/LAGraph.git",
        "0c84c41c561608a49a770569642eaff4bcc7eb8f",
    ),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/LAGraph
install_license LICENSE
# Linux builds throw "undefined reference to 'clock_gettime' and 'clock_settime'" errors if -lrt isn't set
if [[ "${target}" == *-linux-* ]]; then
	atomic_patch -p1 ../patches/lrt-flag.patch
fi
# Account for mallopt not being included in musl 
atomic_patch -p1 ../patches/fix_missing_mallopt_on_musl.patch
cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DGRAPHBLAS_INCLUDE_DIR=${includedir} \
      -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [LibraryProduct("liblagraph", :liblagraph)]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(
        PackageSpec(
            name = "SSGraphBLAS_jll",
            uuid = "7ed9a814-9cab-54e9-8e9e-d9e95b4d61b1",
        );
        platforms = platforms,
    ),
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else
    Dependency(
        PackageSpec(
            name = "CompilerSupportLibraries_jll",
            uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae",
        );
        platforms = filter(!Sys.isbsd, platforms),
    ),
    Dependency(
        PackageSpec(name = "LLVMOpenMP_jll", uuid = "1d63c593-3942-5779-bab2-d838dc0a180e");
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
    julia_compat = "1.6",
    preferred_gcc_version = v"9",
)
