# To ensure a build, it isn't sufficient to modify highs_common.jl.
# You also need to update a line in this file:
#     Last updated: 2024-06-20

include("../highs_common.jl")

script = build_script(shared_libs = "ON")

products = [
    LibraryProduct("libhighs", :libhighs),
    ExecutableProduct("highs", :highs),
]

platforms = expand_cxxstring_abis(platforms)

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("Zlib_jll"),
    HostBuildDependency(PackageSpec(; name="CMake_jll")),
]

build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    preferred_gcc_version = v"6",
    julia_compat = "1.6",
)
