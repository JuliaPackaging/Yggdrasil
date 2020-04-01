using BinaryBuilder, Pkg, Pkg.PlatformEngines

verbose = "--verbose" in ARGS
should_upload = !("--local" in ARGS) 

# Read in input `.json` file
json = String(read(ARGS[1]))
buff = IOBuffer(strip(json))
objs = []
while !eof(buff)
    push!(objs, BinaryBuilder.JSON.parse(buff))
end

# Merge the multiple outputs into one
merged = BinaryBuilder.merge_json_objects(objs)
BinaryBuilder.cleanup_merged_object!(merged)

# Determine build version
name = merged["name"]
version = merged["version"]
# Filter out build-time dependencies that will not go into the dependencies of
# the JLL packages.
dependencies = Dependency[dep for dep in merged["dependencies"] if !isa(dep, BuildDependency)]
lazy_artifacts = merged["lazy_artifacts"]
build_version = BinaryBuilder.get_next_wrapper_version(name, version)

# Register JLL package using given metadata
BinaryBuilder.init_jll_package(
    name,
    joinpath(Pkg.devdir(), "$(name)_jll"),
    "JuliaBinaryWrappers/$(name)_jll.jl",
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

# Filter out build-time dependencies also here
merged["dependencies"] = Dependency[dep for dep in merged["dependencies"] if !isa(dep, BuildDependency)]
mktempdir() do download_dir
    # Grab the binaries for our package
    download_cached_binaries(download_dir, merged["platforms"])
    
    # Push up the JLL package (pointing to as-of-yet missing tarballs)
    repo = "JuliaBinaryWrappers/$(name)_jll.jl"
    tag = "$(name)-v$(build_version)"
    if should_upload
        upload_prefix = "https://github.com/$(repo)/releases/download/$(tag)"
    else
        upload_prefix = "https://julia-bb-buildcache.s3.amazonaws.com/$(bb_hash)/$(proj_hash)/"
    end
    BinaryBuilder.rebuild_jll_package(merged; download_dir=download_dir, upload_prefix=upload_prefix, verbose=verbose, lazy_artifacts=lazy_artifacts)
    
    # Upload them to GitHub releases
    should_upload && BinaryBuilder.upload_to_github_releases(repo, tag, download_dir; verbose=verbose)
end
if should_upload
    BinaryBuilder.push_jll_package(name, build_version)
    BinaryBuilder.register_jll(name, build_version, dependencies)
end
