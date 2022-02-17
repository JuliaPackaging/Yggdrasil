
include("../highs_common.jl")

script = build_script(shared_libs = "OFF")

products = [
    ExecutableProduct("highs", :highs),
]

dependencies = [
    BuildDependency("CompilerSupportLibraries_jll"),
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
