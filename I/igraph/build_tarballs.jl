# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "igraph"
version = v"0.10.15"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/igraph/igraph.git", "635b432eff0a89580ac9bb98068d2fbc8ef374f2")
]

# Bash recipe for building across all platforms
script = raw"""
export USE_CCACHE=0

cd $WORKSPACE/srcdir/igraph/


if [[ "${target}" == *mingw* ]]; then
    LBT=blastrampoline-5
else
    LBT=blastrampoline
fi

if [[ "${target}" == *apple* ]]; then
    LTO=OFF
else
    LTO=ON
fi


CONF_FLAGS="\
    -DBUILD_SHARED_LIBS=ON \
    -DIGRAPH_ENABLE_LTO=${LTO} \
	-DIGRAPH_ENABLE_TLS=ON \
	-DIGRAPH_USE_INTERNAL_BLAS=OFF \
	-DIGRAPH_USE_INTERNAL_LAPACK=OFF \
	-DIGRAPH_USE_INTERNAL_ARPACK=OFF \
	-DIGRAPH_USE_INTERNAL_GLPK=OFF \
	-DIGRAPH_USE_INTERNAL_GMP=OFF \
	-DIGRAPH_USE_INTERNAL_PLFIT=ON \
	-DIGRAPH_GLPK_SUPPORT=ON \
	-DIGRAPH_GRAPHML_SUPPORT=ON \
	-DIGRAPH_OPENMP_SUPPORT=ON \
    -DBLA_VENDOR=blastrampoline -DBLAS_LIBRARIES=\"${LBT}\" -DLAPACK_LIBRARIES=\"${LBT}\" \
    -DBUILD_TESTING=OFF -DIGRAPH_WARNINGS_AS_ERRORS=OFF" # adapted from https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-igraph due to issues on Windows
BB_FLAGS="-DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}"
cmake -B build -DCMAKE_BUILD_TYPE=Release ${BB_FLAGS} ${CONF_FLAGS}

cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> !(Sys.isfreebsd(p) || arch(p) == "riscv64"), platforms)
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libigraph", :libigraph)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Arpack_jll", uuid="68821587-b530-5797-8361-c406ea357684"))
    Dependency(PackageSpec(name="GLPK_jll", uuid="e8aa6df9-e6ca-548a-97ff-1f85fc5b8b98"))
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"); compat="6.2.1")
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"))
    Dependency(PackageSpec(name="XML2_jll", uuid="02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"))
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms))
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8") # early gcc versions cause problems with std::isnan
