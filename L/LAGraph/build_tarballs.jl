# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder, Pkg

name = "LAGraph"
version = v"1.0.2"

sources = [
    GitSource(
        "https://github.com/GraphBLAS/LAGraph.git",
        "7887f54875d5659e701809d623031fe0afd0aa0c",
    ),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/LAGraph
install_license LICENSE
# x86 glibc builds throw "undefined reference to 'clock_gettime' and 'clock_settime'" errors if -lrt isn't set
if [[ "${target}" == *86*-linux-gnu ]]; then
	atomic_patch -p1 ../patches/lrt-flag.patch
fi
cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DGRAPHBLAS_INCLUDE_DIR=${includedir} \
      -DCMAKE_BUILD_TYPE=Release ..
cmake --build . --parallel ${nproc} --target all
cmake --build . --target install
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
    Dependency(
        PackageSpec(
            name = "SSGraphBLAS_jll",
            uuid = "7ed9a814-9cab-54e9-8e9e-d9e95b4d61b1",
        );
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

