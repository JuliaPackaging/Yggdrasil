using BinaryBuilder, BinaryBuilderBase, Downloads, Pkg
using Base.BinaryPlatforms
using GitHub: authenticate

# FIXME: Golang auto-upgrades to HTTP2, this can cause issue like https://github.com/google/go-github/issues/2113
ENV["GODEBUG"] = "http2client=0"

verbose = "--verbose" in ARGS

# Read in input `.json` file, which has one JSON object per line
objs = [BinaryBuilder.JSON.parse(line; dicttype=Dict) for line in eachline(ARGS[1]) if !isempty(strip(line))]

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
dependencies = Dependency[dep for dep in merged["dependencies"] if !(isa(dep, BuildDependency) || isa(dep, HostBuildDependency))]
lazy_artifacts = merged["lazy_artifacts"]
augment_platform_block = merged["augment_platform_block"]
build_version = BinaryBuilder.get_next_wrapper_version(name, version)
repo = "JuliaBinaryWrappers/$(name)_jll.jl"
code_dir = joinpath(Pkg.devdir(), "$(name)_jll")
julia_compat = merged["julia_compat"]

# Register JLL package using given metadata
BinaryBuilder.init_jll_package(
    code_dir,
    repo,
)

function reset_downloader()
    # Downloads.jl hangs when downloading multiple large files (JuliaLang/Downloads.jl#99).
    # Work around that issue by using a fresh Downloader each time.
    lock(Downloads.DOWNLOAD_LOCK) do
        Downloads.DOWNLOADER[] = nothing
    end
end

function mvdir(src, dest)
    for file in readdir(src)
        mv(joinpath(src, file), joinpath(dest, file))
    end
end

function download_cached_binaries(download_dir, build_meta_dir; all_reused::Bool=false)
    NAME = ENV["NAME"]
    PROJECT = ENV["PROJECT"]
    BUILD_ID = ENV["BUILD_ID"]

    artifacts = "$(PROJECT)/products/$(NAME)*.tar.*"
    cmd = `buildkite-agent artifact download --build $BUILD_ID $artifacts $download_dir`
    if !success(pipeline(cmd; stderr))
        # Nothing was built when every tarball is reused
        all_reused && return
        error("Download failed")
    end
    mvdir(joinpath(download_dir, PROJECT, "products"), download_dir)

    # Build metadata is uploaded separately, after the tarballs have been matched up.
    meta = "$(PROJECT)/products/$(NAME)*.meta.json"
    cmd = `buildkite-agent artifact download --build $BUILD_ID $meta $build_meta_dir`
    downloaded = joinpath(build_meta_dir, PROJECT, "products")
    # Older builds have no sidecars; BinaryBuilder will inspect their tarballs instead.
    if success(pipeline(cmd; stderr)) && isdir(downloaded)
        mvdir(downloaded, build_meta_dir)
    else
        @info "No build metadata sidecars in this build; tarballs will be unpacked instead"
    end
end

# The tarballs that `plan_reuse.jl` decided to keep from the previous release, if any
function download_reuse_plan()
    plan = "$(basename(ENV["PROJECT"])).reuse.json"
    dir = mktempdir()
    cmd = `buildkite-agent artifact download --build $(ENV["BUILD_ID"]) $plan $dir`
    success(pipeline(cmd; stderr)) || return nothing
    return BinaryBuilder.JSON.parsefile(joinpath(dir, plan); dicttype=Dict)
end

# Reused tarballs are not downloaded, so their metadata must come from their sidecar.
# The previous release has it, unless it predates reuse: then recover it from the tarball.
function fetch_reused_metadata(plan, objs, build_meta_dir)
    previous_tag = replace(plan["previous"]["tag"], "+" => "%2B")
    asyncmap(plan["reused"]; ntasks=8) do r
        platform = parse(Platform, r["platform"])
        obj = only(o for o in objs if any(p -> triplet(p) == triplet(platform), o["platforms"]))
        tarball_name = basename(r["url"])
        sidecar = joinpath(build_meta_dir, basename(BinaryBuilder.build_meta_path(tarball_name)))
        meta = try
            Downloads.download("https://github.com/$(repo)/releases/download/$(previous_tag)/$(basename(sidecar))", sidecar)
            BinaryBuilder.read_build_meta(tarball_name, obj["products"]; meta_dir=build_meta_dir, verify=false)
        catch
            nothing
        end
        if meta === nothing || meta[1] != r["sha256"] || bytes2hex(meta[2].bytes) != r["git-tree-sha1"]
            tarball = joinpath(build_meta_dir, tarball_name)
            # A JLL with many platforms means hundreds of large downloads from GitHub,
            # some of which stall.
            retry(() -> BinaryBuilderBase.download_verify(r["url"], r["sha256"], tarball);
                  delays=ExponentialBackOff(n=4, first_delay=10))()
            tarball_hash, git_hash, products_info = BinaryBuilder.inspect_tarball(tarball, platform, obj["products"])
            if bytes2hex(git_hash.bytes) != r["git-tree-sha1"]
                error("$(tarball_name) does not have the tree hash recorded in the previous release")
            end
            BinaryBuilder.write_build_meta(tarball, tarball_hash, git_hash, products_info)
            rm(tarball)
        end
    end
end

function download_binaries_from_release(download_dir)
    function do_download(download_dir, info)
        url = info["url"]
        hash = info["sha256"]
        filename = basename(url)
        reset_downloader()
        print("Downloading $url... ")
        BinaryBuilderBase.download_verify(url, hash, joinpath(download_dir, filename))
        println("done")
    end

    # Download the tarballs reading the information in the current `Artifacts.toml`.
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
    json_obj["dependencies"] = Dependency[dep for dep in json_obj["dependencies"] if BinaryBuilderBase.is_runtime_dependency(dep)]
end
skip_build = get(ENV, "SKIP_BUILD", "false") == "true"
reuse_plan = skip_build ? nothing : download_reuse_plan()
reused = reuse_plan === nothing ? Dict{String,Any}[] : reuse_plan["reused"]
# This directory is separate because `download_dir` is uploaded to GitHub.
build_meta_dir = mktempdir()
mktempdir() do download_dir
    # Grab the binaries for our package
    if skip_build
        # We only want to update the wrappers, so download the tarballs from the
        # latest build. Released tarballs do not include metadata sidecars.
        download_binaries_from_release(download_dir)
    else
        # We are going to publish the new binaries we've just baked, take them
        # out of the cache while they're hot.
        download_cached_binaries(download_dir, build_meta_dir;
                                 all_reused=length(reused) == length(merged["platforms"]))
        isempty(reused) || fetch_reused_metadata(reuse_plan, objs_unmerged, build_meta_dir)
    end

    # Push up the JLL package (pointing to as-of-yet missing tarballs)
    tag = "$(name)-v$(build_version)"
    upload_prefix = "https://github.com/$(repo)/releases/download/$(tag)"

    # If we didn't rebuild the tarballs, save the original Artifacts.toml
    artifacts_toml = skip_build ? read(joinpath(code_dir, "Artifacts.toml"), String) : ""
    # This loop over the unmerged objects necessary in the event that we have multiple packages being built by a single build_tarballs.jl
    for (i,json_obj) in enumerate(objs_unmerged)
        from_scratch = (i == 1)
        obj_triplets = Set(triplet.(json_obj["platforms"]))
        reused_urls = String[r["url"] for r in reused if triplet(parse(Platform, r["platform"])) in obj_triplets]
        BinaryBuilder.rebuild_jll_package(json_obj; download_dir, build_meta_dir, upload_prefix, verbose, from_scratch, reused_urls)
    end

    # Restore Artifacts.toml
    if skip_build
        write(joinpath(code_dir, "Artifacts.toml"), artifacts_toml)
    end

    # Push JLL package _before_ uploading to GitHub releases, so that this version of the code is what gets tagged
    BinaryBuilder.push_jll_package(name, build_version)

    if !skip_build
        # Publish the build metadata along with the tarballs, so that a later release can
        # reuse them without unpacking them.
        for file in readdir(build_meta_dir)
            endswith(file, ".meta.json") && cp(joinpath(build_meta_dir, file), joinpath(download_dir, file))
        end
        # Upload the tarballs to GitHub releases
        BinaryBuilder.upload_to_github_releases(repo, tag, download_dir; verbose=verbose)
    end
end

# Sub off to Registrator to create a PR to General.  Note: it's important to pass both
# `augment_platform_block` and `lazy_artifacts` to build the right Project dictionary
register_gh_auth = authenticate(ENV["REGISTRY_GITHUB_TOKEN"])
BinaryBuilder.register_jll(name, build_version, dependencies, julia_compat;
                           augment_platform_block, lazy_artifacts, gh_auth=register_gh_auth)
