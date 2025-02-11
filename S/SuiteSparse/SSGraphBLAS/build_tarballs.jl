include("../common.jl")

name = "SSGraphBLAS"
version = v"9.3.1"

SS_version_str = "7.8.3"
SS_version = VersionNumber(SS_version_str)

sources = suitesparse_sources(SS_version)

# Bash recipe for building across all platforms
script = raw"""
# Until upstream is fixed, set the cache path to something useless
# This is a runtime error that will be handled in the downstream library.
export GRAPHBLAS_CACHE_PATH=/workspace/srcdir
PROJECTS_TO_BUILD="graphblas"
CMAKE_OPTIONS+=(
        -DSUITESPARSE_USE_SYSTEM_SUITESPARSE_CONFIG=ON
        -DGRAPHBLAS_CROSS_TOOLCHAIN_FLAGS_NATIVE="-DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN}"
        --debug-trycompile
    )
if [[ "$target" == *-mingw* ]]; then
    CMAKE_OPTIONS+="-DGBNCPUFEAT=1"
fi
""" * build_script(; use_omp=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libgraphblas", :libgraphblas),
]

# Add dependency on SuiteSparse_jll
dependencies = append!(dependencies, [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
    Dependency("SuiteSparse_jll"; compat = "=$SS_version_str")
])

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, 
               products, dependencies; preferred_gcc_version=v"9", julia_compat="1.12")
