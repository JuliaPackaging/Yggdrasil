using BinaryBuilder2
using BinaryBuilder2: import_archives

# Registers the projects given in `ARGS`, in order.  They all go through one `BuildMeta`,
# so their versions stack on top of each other in the JLL repository, and each version gets
# its own registry pull request, based on the pull request of the version before it.
meta = BuildMeta(;
    universe_name=get(ENV, "BB2_UNIVERSE", nothing),
    deploy_org="JuliaBinaryWrappers",
    register="JuliaRegistries/General",
    verbose=true,
)

for project in ARGS
    # Import the archives built for this project, then run its `build_tarballs.jl`, which
    # finds everything in the build cache and so only packages and registers.
    import_archives(meta.build_cache, joinpath(project, "products"))
    run_build_tarballs(meta, joinpath(project, "build_tarballs.jl"))
end
