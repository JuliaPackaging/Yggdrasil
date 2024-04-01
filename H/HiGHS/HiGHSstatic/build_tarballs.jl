# To ensure a build, it isn't sufficient to modify highs_common.jl.
# You also need to update a line in this file:
#     Last updated: 2024-04-02

include("../highs_common.jl")

# !!! warning
#     Temporarily over-ride the `version` so that we can make a new release that
#     removes the Zlib_jll dependency. If you're updating HiGHS to a new version
#     you should delete this line.
version = v"1.7.1"

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
    # !!! warning
    #     TODOW(odow): temporarily disable Zlib_jll because it is not linked correctly.
    #     Debug with upstream.
    # Dependency("Zlib_jll"),
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
