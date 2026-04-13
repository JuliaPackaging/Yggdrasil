using BinaryBuilder2
using BinaryBuilder2: import_archives

meta = BuildMeta(;
    deploy_org="JuliaBinaryWrappers",
    register=true,
)

# Import archives from `products`
import_archives(meta.build_cache, "products")

# Then run build_tarballs.jl; this shouldn't build anything
run_build_tarballs(meta, "build_tarballs.jl")
