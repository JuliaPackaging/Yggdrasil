# Exports the JLLs registered in a local BinaryBuilder2 universe, which deployed nothing,
# into a depot from which any Julia from v1.3 on installs them next to `General`:
#
#   registries/<registry>/   the universe's registry of the JLLs, without git history
#   packages/<Name>/<slug>/  each registered JLL version, where Pkg looks for it
#   artifacts/<hash>/        the artifacts of each JLL version, for every platform
#   jlls.txt                 `Name_jll@version` of each JLL version, in registration order
#
# Registering a new version of a JLL replaces the git history of its repository in the
# universe, so `export_jll_versions!()` must run after each registration; it adds the JLL
# versions of the universe's registry that the depot does not hold yet.  Afterwards,
# `export_registries!()` adds the registry.

import TOML
using Base: SHA1, UUID

const GENERAL_UUID = "23338594-aafe-5451-b93e-139f81909106"

# The universe's own registries, which hold the JLLs that it registered
function registry_dirs(universe_depot::String)
    registries = joinpath(universe_depot, "registries")
    return filter(joinpath.(registries, readdir(registries))) do dir
        registry_toml = joinpath(dir, "Registry.toml")
        return isfile(registry_toml) && TOML.parsefile(registry_toml)["uuid"] != GENERAL_UUID
    end
end

function artifact_tree_hashes(artifacts_toml::String)
    hashes = Set{String}()
    isfile(artifacts_toml) || return hashes
    for (_, entries) in TOML.parsefile(artifacts_toml)
        for entry in (entries isa AbstractVector ? entries : [entries])
            push!(hashes, entry["git-tree-sha1"])
        end
    end
    return hashes
end

function find_artifact(universe_depot::String, hash::String)
    for depot in [universe_depot; DEPOT_PATH]
        path = joinpath(depot, "artifacts", hash)
        isdir(path) && return realpath(path)
    end
    error("artifact $(hash) is not in the universe")
end

function export_jll_versions!(universe_depot::String, out_depot::String)
    for registry in registry_dirs(universe_depot)
        for (uuid, entry) in TOML.parsefile(joinpath(registry, "Registry.toml"))["packages"]
            name = entry["name"]
            versions = TOML.parsefile(joinpath(registry, entry["path"], "Versions.toml"))
            for version in sort(collect(keys(versions)); by=VersionNumber)
                tree_hash = versions[version]["git-tree-sha1"]
                slug = Base.version_slug(UUID(uuid), SHA1(tree_hash))
                dest = joinpath(out_depot, "packages", name, slug)
                isdir(dest) && continue

                repo = joinpath(universe_depot, "dev", name)
                if !success(`git -C $(repo) cat-file -e $(tree_hash)`)
                    error("$(name) v$(version) (tree $(tree_hash)) is no longer in $(repo)")
                end
                mkpath(dest)
                run(pipeline(`git -C $(repo) archive --format=tar $(tree_hash)`, `tar -x -C $(dest)`))

                hashes = artifact_tree_hashes(joinpath(dest, "Artifacts.toml"))
                mkpath(joinpath(out_depot, "artifacts"))
                for hash in hashes
                    artifact = joinpath(out_depot, "artifacts", hash)
                    isdir(artifact) || cp(find_artifact(universe_depot, hash), artifact; follow_symlinks=false)
                end
                open(io -> println(io, "$(name)@$(version)"), joinpath(out_depot, "jlls.txt"), "a")
                @info("Exported $(name) v$(version)", artifacts=length(hashes))
            end
        end
    end
end

function export_registries!(universe_depot::String, out_depot::String)
    for registry in registry_dirs(universe_depot)
        dest = joinpath(out_depot, "registries", basename(registry))
        rm(dest; force=true, recursive=true)
        mkpath(dirname(dest))
        cp(registry, dest)
        rm(joinpath(dest, ".git"); force=true, recursive=true)
    end
end
