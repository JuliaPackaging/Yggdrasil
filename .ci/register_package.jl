using BinaryBuilder, Pkg, Pkg.PlatformEngines

verbose = "--verbose" in ARGS

# Read in input `.json` file
json = String(read(ARGS[1]))
buff = IOBuffer(strip(json))
objs = []
while !eof(buff)
    push!(objs, BinaryBuilder.JSON.parse(buff))
end

# Merging modifies `obj`, so let's keep an unmerged version around
objs_unmerged = deepcopy(objs)

# Merge the multiple outputs into one
merged = BinaryBuilder.merge_json_objects(objs)
BinaryBuilder.cleanup_merged_object!(merged)
BinaryBuilder.cleanup_merged_object!.(objs_unmerged)

# Determine build version
name = merged["name"]
version = merged["version"]
# Filter out build-time dependencies that will not go into the dependencies of
# the JLL packages.
dependencies = Dependency[dep for dep in merged["dependencies"] if !isa(dep, BuildDependency)]
lazy_artifacts = merged["lazy_artifacts"]
build_version = BinaryBuilder.get_next_wrapper_version(name, version)
repo = "JuliaBinaryWrappers/$(name)_jll.jl"
code_dir = joinpath(Pkg.devdir(), "$(name)_jll")
julia_compat = merged["julia_compat"]

# Register JLL package using given metadata
BinaryBuilder.init_jll_package(
    name,
    code_dir,
    repo,
)

function download_cached_binaries(download_dir, platforms)
    # Grab things out of the aether for maximum consistency
    bb_hash = ENV["BB_HASH"]
    proj_hash = ENV["PROJ_HASH"]
    probe_platform_engines!(;verbose=verbose)

    for platform in platforms
        url = "https://julia-bb-buildcache.s3.amazonaws.com/$(bb_hash)/$(proj_hash)/$(triplet(platform)).tar.gz"
        filename = "$(name).v$(version).$(triplet(platform)).tar.gz"
        PlatformEngines.download(url, joinpath(download_dir, filename); verbose=verbose)
    end
end

function download_binaries_from_release(download_dir)

    function do_download(download_dir, info)
        url = info["url"]
        hash = info["sha256"]
        filename = basename(url)
        PlatformEngines.download_verify(url, hash, joinpath(download_dir, filename); verbose=verbose)
    end

    probe_platform_engines!(;verbose=verbose)

    # Doownload the tarballs reading the information in the current `Artifacts.toml`.
    artifacts = Pkg.Artifacts.load_artifacts_toml(joinpath(code_dir, "Artifacts.toml"))[name]
    if artifacts isa Dict
        # If it's a Dict, that means this is an AnyPlatform artifact, act accordingly.
        info = artifacts["download"][1]
        do_download(download_dir, info)
    else
        # Otherwise, it's a Vector, and we must iterate over all platforms.
        for artifact in artifacts
            info = artifact["download"][1]
            do_download(download_dir, info)
        end
    end
end

# Filter out build-time dependencies also here
for json_obj in [merged, objs_unmerged...]
    json_obj["dependencies"] = Dependency[dep for dep in json_obj["dependencies"] if !isa(dep, BuildDependency)]
end
skip_build = get(ENV, "SKIP_BUILD", "false") == "true"
mktempdir() do download_dir
    # Grab the binaries for our package
    if skip_build
        # We only want to update the wrappers, so download the tarballs from the
        # latest build.
        download_binaries_from_release(download_dir)
    else
        # We are going to publish the new binaries we've just baked, take them
        # out of the cache while they're hot.
        download_cached_binaries(download_dir, merged["platforms"])
    end

    # Push up the JLL package (pointing to as-of-yet missing tarballs)
    tag = "$(name)-v$(build_version)"
    upload_prefix = "https://github.com/$(repo)/releases/download/$(tag)"

    # If we didn't rebuild the tarballs, save the original Artifacts.toml
    artifacts_toml = skip_build ? read(joinpath(code_dir, "Artifacts.toml"), String) : ""
    # This loop over the unmerged objects necessary in the event that we have multiple packages being built by a single build_tarballs.jl
    for (i,json_obj) in enumerate(objs_unmerged)
        from_scratch = (i == 1)
        BinaryBuilder.rebuild_jll_package(json_obj; download_dir=download_dir, upload_prefix=upload_prefix, verbose=verbose, lazy_artifacts=json_obj["lazy_artifacts"], from_scratch=from_scratch)
    end

    if skip_build
        # Restore Artifacts.toml
        write(joinpath(code_dir, "Artifacts.toml"), artifacts_toml)
    else
        # Upload the tarballs to GitHub releases
        BinaryBuilder.upload_to_github_releases(repo, tag, download_dir; verbose=verbose)
    end
end
BinaryBuilder.push_jll_package(name, build_version)
BinaryBuilder.register_jll(name, build_version, dependencies, julia_compat)
