# To ensure a build, it isn't sufficient to modify highs_common.jl.
# You also need to update a line in this file:
#     Last updated: 2025-06-07

include("../highs_common.jl")

script = build_script(shared_libs = "OFF")

products = [
    ExecutableProduct("highs", :highs),
]

# In addition to BSD systems, we don't need to expand the C++ string ABI on Windows, because
# we're doing a fully static build, so no need to match user's libstdc++.
platforms = expand_cxxstring_abis(platforms; skip=!Sys.islinux)

dependencies = [
    # We do fully static build only on Windows, so in that case `CompilerSupportLibraries_jll`
    # is a build-only dependency, in the other cases it's also a runtime one.
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.iswindows, platforms)),
    BuildDependency("CompilerSupportLibraries_jll"; platforms=filter(Sys.iswindows, platforms)),
    Dependency("METIS_jll"),
    Dependency("OpenBLAS32_jll"),
    HostBuildDependency(PackageSpec(; name="CMake_jll")),
    Dependency("Zlib_jll"),
]

build_tarballs(
    ARGS,
    name * "static",
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    preferred_gcc_version = v"6",
    julia_compat = "1.6",
)
