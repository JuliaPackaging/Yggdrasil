#!/usr/bin/env julia

using Pkg, SHA, BinaryBuilderBase, Pkg.BinaryPlatforms, Pkg.Artifacts

include("common.jl")

function find_old_shards(name::String)
    all_shards = BinaryBuilderBase.all_compiler_shards()
    max_version = maximum([s.version for s in all_shards if s.name == name])
    return [s for s in all_shards if s.name == name && s.version != max_version]
end


artifacts_toml = joinpath(dirname(dirname(pathof(BinaryBuilderBase))), "Artifacts.toml")
function unbind_shard(cs::CompilerShard)
    @info("Unbinding $(repr(cs))")
    unbind_artifact!(artifacts_toml, BinaryBuilderBase.artifact_name(cs))
end

unbind_shard.(find_old_shards("Rootfs"))
unbind_shard.(find_old_shards("PlatformSupport"))
