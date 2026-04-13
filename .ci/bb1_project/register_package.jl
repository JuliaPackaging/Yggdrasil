using BinaryBuilder, BinaryBuilderBase, Downloads, Pkg

# FIXME: Golang auto-upgrades to HTTP2, this can cause issue like https://github.com/google/go-github/issues/2113
ENV["GODEBUG"] = "http2client=0"

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

function download_cached_binaries(download_dir)
    NAME = ENV["NAME"]
    PROJECT = ENV["PROJECT"]
    artifacts = "$(PROJECT)/products/$(NAME)*.tar.*"
    cmd = `buildkite-agent artifact download $artifacts $download_dir`
    if !success(pipeline(cmd; stderr))
        error("Download failed")
    end
    mvdir(joinpath(download_dir, PROJECT, "products"), download_dir)
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
mktempdir() do download_dir
    # Grab the binaries for our package
    if skip_build
        # We only want to update the wrappers, so download the tarballs from the
        # latest build.
        download_binaries_from_release(download_dir)
    else
        # We are going to publish the new binaries we've just baked, take them
        # out of the cache while they're hot.
        download_cached_binaries(download_dir)
    end

    # Push up the JLL package (pointing to as-of-yet missing tarballs)
    tag = "$(name)-v$(build_version)"
    upload_prefix = "https://github.com/$(repo)/releases/download/$(tag)"

    # If we didn't rebuild the tarballs, save the original Artifacts.toml
    artifacts_toml = skip_build ? read(joinpath(code_dir, "Artifacts.toml"), String) : ""
    # This loop over the unmerged objects necessary in the event that we have multiple packages being built by a single build_tarballs.jl
    for (i,json_obj) in enumerate(objs_unmerged)
        from_scratch = (i == 1)
        BinaryBuilder.rebuild_jll_package(json_obj; download_dir, upload_prefix, verbose, from_scratch)
    end

    # Restore Artifacts.toml
    if skip_build
        write(joinpath(code_dir, "Artifacts.toml"), artifacts_toml)
    end

    # Push JLL package _before_ uploading to GitHub releases, so that this version of the code is what gets tagged
    BinaryBuilder.push_jll_package(name, build_version)

    if !skip_build
        # Upload the tarballs to GitHub releases
        BinaryBuilder.upload_to_github_releases(repo, tag, download_dir; verbose=verbose)
    end
end

# Sub off to Registrator to create a PR to General.  Note: it's important to pass both
# `augment_platform_block` and `lazy_artifacts` to build the right Project dictionary
BinaryBuilder.register_jll(name, build_version, dependencies, julia_compat; augment_platform_block, lazy_artifacts)
