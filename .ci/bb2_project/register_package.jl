using BinaryBuilder2
using BinaryBuilder2: import_archives

universe_name = nothing
if get(ENV, "BUILDKITE_PULL_REQUEST", "false") != "false"
    universe_name = "$(get(ENV, "BUILDKITE_COMMIT", "1a2b3c4d")[1:8])"
end

meta = BuildMeta(;
    deploy_org="JuliaBinaryWrappers",
    register=true,
    universe_name,
)

# Import archives from `products`
import_archives(meta.build_cache, "products")

# Then run build_tarballs.jl; this shouldn't build anything
run_build_tarballs(meta, "build_tarballs.jl")
