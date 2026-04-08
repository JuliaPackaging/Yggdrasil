include("../common.jl")

name = "SSGraphBLAS"
version = v"10.3.1"

function gb_to_ss_version(version::VersionNumber)
    # Version map started when GraphBLAS decoupled from SS dependency. Everything before here
    # has a dependency on SS in the registry and can't be rebuilt easily.
    ss_version = Dict(
        v"10.3.1" => v"7.12.2",
    )
    return ss_version[version]
end

sources = suitesparse_sources(gb_to_ss_version(version))

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

dependencies = append!(dependencies, [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),

    # SSGraphBLAS doesn't actually depend on SuiteSparse, it is just shipped inside of it and needs the basic infrastructure to be around
    # in the build system, but not when running
    BuildDependency("SuiteSparse_jll"),
])

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms,
               products, dependencies; preferred_gcc_version=v"9", julia_compat="1.10")
