using BinaryBuilder, Pkg

name = "SSGraphBLAS"
version = v"5.1.7"

# Collection of sources required to build SuiteSparse:GraphBLAS
sources = [
    GitSource("https://github.com/DrTimothyAldenDavis/GraphBLAS.git",
        "905b1d54bef971db70180933454f65ab1f6f364b")
]

# Bash recipe for building across all platforms
script = raw"""
# Compile GraphBLAS
cd $WORKSPACE/srcdir/GraphBLAS
make -j${nproc} CMAKE_OPTIONS="-DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}"
make install
if [[ ! -f "${libdir}/libgraphblas.${dlext}" ]]; then
    # For mysterious reasons, the shared library is not installed
    # when building for Windows
    mkdir -p "${libdir}"
    cp "build/libgraphblas.${dlext}" "${libdir}"
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libgraphblas", :libgraphblas),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"6", julia_compat="1.6")
