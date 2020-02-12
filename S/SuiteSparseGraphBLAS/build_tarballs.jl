using BinaryBuilder

name = "SuiteSparseGraphBLAS"
version = v"5.6.0"

# Collection of sources required to build SuiteSparse
sources = [
    FileSource("https://github.com/DrTimothyAldenDavis/SuiteSparse/archive/v$(version).tar.gz",
               "76d34d9f6dafc592b69af14f58c1dc59e24853dcd7c2e8f4c98ffa223f6a1adb")
]

# Bash recipe for building across all platforms
script = raw"""
# Compile GraphBLAS
cd $WORKSPACE/srcdir/SuiteSparse-*/GraphBLAS/build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} ..
make -j${nproc} install
if [[ ! -f "${libdir}/libgraphblas.${dlext}" ]]; then
    # For mysterious reasons, the shared library is not installed
    # when building for Windows
    mkdir -p "${libdir}"
    cp "libgraphblas.${dlext}" "${libdir}"
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libgraphblas", :libgraphblas),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
