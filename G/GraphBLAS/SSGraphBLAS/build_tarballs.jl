using BinaryBuilder, Pkg

name = "SSGraphBLAS"
version = v"4,0.3"

# Collection of sources required to build SuiteSparse
sources = [
    ArchiveSource("https://github.com/DrTimothyAldenDavis/GraphBLAS/archive/v4.0.3.tar.gz",
        "43519783625f1a0a631158603850cfcf0d9681646dbb5c64ae2eaf27e1444b90")
]

# Bash recipe for building across all platforms
script = raw"""
# Compile GraphBLAS
cd $WORKSPACE/srcdir/GraphBLAS-*/build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DUSER_NONE=1

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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"6")
