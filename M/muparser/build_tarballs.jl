# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "muparser"
version = v"2.3.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/beltoforion/muparser", "fbafd7f8774af2b53f4d2de07c57353fcfc09216"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/muparser

CMAKE_FLAGS=(
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DCMAKE_BUILD_TYPE=Release
    -DBUILD_SHARED_LIBS=ON
    -DBUILD_TESTING=OFF
    -DENABLE_OPENMP=ON
    -DENABLE_SAMPLES=OFF
)

cmake -Bbuild ${CMAKE_FLAGS[@]}
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libmuparser", :libmuparser)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms=filter(Sys.isbsd, platforms)),

]

# Build the tarballs, and possibly a `build.jl` as well.
# We need C++ 20, and this requires at least GCC 8
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8")
