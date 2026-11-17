using BinaryBuilder2
using BinaryBuilder2: import_archives

# Registers the projects given in `ARGS`, in order.  They all go through one `BuildMeta`,
# so their versions stack on top of each other in the JLL repository, and each version gets
# its own registry pull request, based on the pull request of the version before it.
#
# With `BB2_EXPORT_DIR` set (for the load check), nothing is deployed or registered anywhere:
# the projects are registered into a throwaway local universe, and each JLL version that
# it registers is exported, with the universe's registry, to a depot in that directory
# (see `load_check/export_depot.jl`).
const EXPORT_DIR = get(ENV, "BB2_EXPORT_DIR", nothing)
EXPORT_DIR === nothing || include(joinpath(@__DIR__, "load_check", "export_depot.jl"))
meta = BuildMeta(;
    universe_name=EXPORT_DIR === nothing ? get(ENV, "BB2_UNIVERSE", nothing) : nothing,
    deploy_org=EXPORT_DIR === nothing ? "JuliaBinaryWrappers" : nothing,
    register=EXPORT_DIR === nothing ? "JuliaRegistries/General" : false,
    verbose=true,
)

for project in ARGS
    # Import the archives built for this project, then run its `build_tarballs.jl`, which
    # finds everything in the build cache and so only packages and registers.
    import_archives(meta.build_cache, joinpath(project, "products"))
    run_build_tarballs(meta, joinpath(project, "build_tarballs.jl"))
    # The universe keeps only the latest version of each JLL, so export them right away
    EXPORT_DIR === nothing || export_jll_versions!(meta.universe.depot_path, EXPORT_DIR)
end
EXPORT_DIR === nothing || export_registries!(meta.universe.depot_path, EXPORT_DIR)
