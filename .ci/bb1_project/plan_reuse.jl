# Decide which platforms of a project need building, and which can reuse the tarball of
# the previous release because nothing that goes into it changed.
#
#     julia plan_reuse.jl <project> <jll name> <meta.json> <platforms.list> <reuse.json>
#
# The previous release's README names the Yggdrasil commit that built it.  The recipe is
# evaluated at that commit too, and a platform is reused when its build description
# (sources, script, products, build dependencies and build options) is the same in both.
# `<platforms.list>` is rewritten to the platforms that still need building, and
# `<reuse.json>` lists the reused tarballs for the registration step.
#
# Everything is rebuilt when the previous release can't be located, when anything goes
# wrong while planning, or when the rebuild trigger in the recipe changed.

using BinaryBuilder, BinaryBuilderBase, Downloads, Pkg, TOML
using BinaryBuilder: JSON
using Base.BinaryPlatforms

const YGGDRASIL_BASE = dirname(dirname(@__DIR__))

function read_meta(path)
    return [JSON.parse(line; dicttype=Dict) for line in eachline(path) if !isempty(strip(line))]
end

function latest_registered_version(jll)
    for reg in Pkg.Registry.reachable_registries()
        for uuid in Pkg.Registry.uuids_from_name(reg, jll)
            info = Pkg.Registry.registry_info(reg, reg[uuid])
            versions = [v for (v, vinfo) in info.version_info if !vinfo.yanked]
            isempty(versions) || return maximum(versions)
        end
    end
    return nothing
end

fetch_text(url) = String(take!(Downloads.download(url, IOBuffer())))

git(args...) = readchomp(Cmd(`git $args`; dir=YGGDRASIL_BASE))
git_ok(args...) = success(Cmd(`git $args`; dir=YGGDRASIL_BASE))

# The recipe's `# Build trigger: N` line, if any
build_trigger(recipe) = [m.match for m in eachmatch(r"(?im)^#\s*(re)?build trigger.*$", recipe)]

# Everything about a build that can affect its tarballs.  Version pins and git revisions
# of dependencies are part of their JSON; compat bounds only matter through the build
# version they imply, and runtime-only dependencies aren't installed for the build.
function fingerprint(obj, project, rev)
    sources = map(obj["sources"]) do source
        source = copy(source)
        if source["type"] == "directory"
            # Only the path is recorded, so add the contents
            path = normpath(joinpath(project, source["path"]))
            source["tree"] = git_ok("rev-parse", "--verify", "--quiet", "$(rev):$(path)") ?
                             git("rev-parse", "$(rev):$(path)") : nothing
        end
        source
    end
    dependencies = [delete!(copy(dep), "compat") for dep in obj["dependencies"]
                    if dep["type"] != "runtimedependency"]
    return JSON.json(Dict(
        "sources" => sources,
        "script" => obj["script"],
        "products" => obj["products"],
        "dependencies" => dependencies,
        "build_options" => obj["build_options"],
    ))
end

platform_tags(p::AbstractPlatform) = Dict{String,String}(k => string(v) for (k, v) in tags(p))
platform_tags(entry::Dict) =
    Dict{String,String}(k => string(v) for (k, v) in entry if k ∉ ("git-tree-sha1", "download", "lazy"))

function plan(project, jll, head_meta)
    no_reuse(reason) = (; reason, previous=nothing, reused=Dict{String,Any}[])

    # Older versions of BinaryBuilderBase drop version pins and git revisions when
    # serializing dependencies, which would hide e.g. a new LLVM_full build.
    if !haskey(JSON.lower(Dependency("Zlib_jll", v"1.2.13")), "build_version")
        return no_reuse("this BinaryBuilderBase does not serialize dependency versions")
    end

    version = latest_registered_version("$(jll)_jll")
    version === nothing && return no_reuse("$(jll)_jll has not been registered yet")
    tag = "$(jll)-v$(version)"
    raw = "https://raw.githubusercontent.com/JuliaBinaryWrappers/$(jll)_jll.jl/$(replace(tag, "+" => "%2B"))"
    readme, artifacts = try
        fetch_text("$(raw)/README.md"), TOML.parse(fetch_text("$(raw)/Artifacts.toml"))
    catch err
        return no_reuse("cannot fetch $(tag): $(sprint(showerror, err))")
    end
    m = match(r"JuliaPackaging/Yggdrasil/blob/([0-9a-f]{40})/(\S+)/build_tarballs\.jl", readme)
    m === nothing && return no_reuse("the README of $(tag) does not name the commit that built it")
    commit, built_from = m.captures
    built_from == project || return no_reuse("$(tag) was built from $(built_from)")
    if !git_ok("cat-file", "-e", "$(commit)^{commit}")
        git_ok("fetch", "--quiet", "origin", commit) ||
            return no_reuse("cannot fetch $(commit), which built $(tag)")
    end
    previous = Dict("version" => string(version), "tag" => tag, "commit" => commit)

    recipe(rev) = git("show", "$(rev):$(project)/build_tarballs.jl")
    if build_trigger(recipe(commit)) != build_trigger(recipe("HEAD"))
        return (; reason="the rebuild trigger changed", previous, reused=Dict{String,Any}[])
    end

    # Evaluate the recipe as it was when the previous release was built
    base_meta = mktempdir() do dir
        worktree = joinpath(dir, "yggdrasil")
        git("worktree", "add", "--quiet", "--detach", worktree, commit)
        try
            meta_path = joinpath(dir, "base.meta.json")
            run(Cmd(`$(Base.julia_cmd()) --project=$(Base.active_project()) --compile=min
                     build_tarballs.jl --meta-json=$(meta_path)`; dir=joinpath(worktree, project)))
            read_meta(meta_path)
        finally
            git("worktree", "remove", "--force", worktree)
        end
    end

    previous_fingerprints = Dict{Tuple{String,String},String}()
    for obj in base_meta
        haskey(obj, "build_options") || return no_reuse("the build description lacks build options")
        fp = fingerprint(obj, project, commit)
        for p in obj["platforms"]
            previous_fingerprints[(obj["name"], p)] = fp
        end
    end
    entries = get(artifacts, jll, [])
    entries isa Vector || return no_reuse("$(tag) has a platform-independent artifact")

    reused = Dict{String,Any}[]
    for obj in head_meta
        obj["name"] == jll || continue
        fp = fingerprint(obj, project, "HEAD")
        for p in obj["platforms"]
            get(previous_fingerprints, (jll, p), nothing) == fp || continue
            tags = platform_tags(parse(Platform, p))
            i = findfirst(e -> platform_tags(e) == tags, entries)
            i === nothing && continue
            download = only(entries[i]["download"])
            push!(reused, Dict("platform" => p, "url" => download["url"], "sha256" => download["sha256"],
                               "git-tree-sha1" => entries[i]["git-tree-sha1"]))
        end
    end
    return (; reason="", previous, reused)
end

function main(project, jll, meta_path, platforms_path, plan_path)
    result = try
        plan(project, jll, read_meta(meta_path))
    catch err
        @error "Could not determine which tarballs to reuse" exception=(err, catch_backtrace())
        (; reason="planning failed", previous=nothing, reused=Dict{String,Any}[])
    end
    if result.previous === nothing || isempty(result.reused)
        @info "Building all platforms of $(project)" reason=result.reason
    end
    canonical(p) = triplet(parse(Platform, p))
    reused = Set(canonical(r["platform"]) for r in result.reused)
    platforms = split(readchomp(platforms_path))
    to_build = filter(p -> canonical(p) ∉ reused, platforms)
    @info "Reusing $(length(reused)) of $(length(platforms)) tarballs of $(project)" previous=result.previous
    write(platforms_path, join(to_build, " "), "\n")
    open(plan_path, "w") do io
        JSON.print(io, Dict("previous" => result.previous, "reused" => result.reused), 2)
    end
end

main(ARGS...)
