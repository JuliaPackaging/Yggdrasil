
include("../highs_common.jl")

script = build_script(shared_libs = "OFF")

products = [
    ExecutableProduct("highs", :highs),
]

dependencies = [
    # We do fully static build only on Windows, so in that case `CompilerSupportLibraries_jll`
    # is a build-only dependency, in the other cases it's also a runtime one.
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.iswindows, platforms)),
    BuildDependency("CompilerSupportLibraries_jll"; platforms=filter(Sys.iswindows, platforms)),
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
