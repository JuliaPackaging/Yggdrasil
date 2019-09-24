using SHA, BinaryBuilder, Pkg, Pkg.BinaryPlatforms, Pkg.Artifacts
using BinaryBuilder: TarballDependency, CompilerShard

host_platform = Linux(:x86_64; libc=:musl)

if !haskey(ENV, "GITHUB_TOKEN")
    error("export GITHUB_TOKEN you dolt!")
end

# Test if something is older than a reference, or doesn't exist
function is_outdated(test, reference)
    if !isfile(test)
        return true
    end
    return stat(test).mtime < stat(reference).mtime
end

function unpacked_to_squashfs(unpacked_hash::Base.SHA1, name, version; platform=host_platform, target=nothing)
    path = artifact_path(unpacked_hash)
    squashfs_cs = CompilerShard(name, version, platform, :squashfs; target=target)
    art_name = BinaryBuilder.artifact_name(squashfs_cs)
    squash_hash = create_artifact() do target_dir
        target_squashfs = joinpath(target_dir, art_name)
        success(`mksquashfs $(path) $(target_squashfs) -force-uid 0 -force-gid 0 -comp xz -b 1048576 -Xdict-size 100% -noappend`)
    end
    @info("$(art_name) hash: $(bytes2hex(squash_hash.bytes))")
    return squash_hash
end

# Generate artifacts for a given path, creating both an unpacked version and a squashfs version
function generate_artifacts(path::AbstractString, name, version; platform=host_platform, target=nothing)
    if !isdir(path)
        error("$path is not a directory!")
    end

    # First, the unpacked version
    squashfs_cs = CompilerShard(name, version, platform, :unpacked; target=target)
    art_name = BinaryBuilder.artifact_name(squashfs_cs)
    unpacked_hash = create_artifact() do target
        rm(target; force=true, recursive=true)
        cp(path, target)
    end
    @info("$(art_name) hash: $(bytes2hex(unpacked_hash.bytes))")

    # Next, the squashfs version
    squashfs_hash = unpacked_to_squashfs(unpacked_hash, name, version; platform=platform, target=target)
    return (unpacked_hash, squashfs_hash)
end

function publish_artifact(repo::AbstractString, tag::AbstractString, hash::Base.SHA1, filename::AbstractString)
    mktempdir() do dir
        tarball_hash = archive_artifact(hash, joinpath(dir, "$(filename).tar.gz"))
        BinaryBuilder.upload_to_github_releases(repo, tag, dir)
        return tarball_hash
    end
end

function upload_compiler_shard(repo, name, version, hash, archive_type; platform=host_platform, target=nothing)
    cs = CompilerShard(name, version, platform, archive_type; target=target)
    tag = BinaryBuilder.get_tag_name(name, BinaryBuilder.get_next_wrapper_version(name, version))
    filename = BinaryBuilder.artifact_name(cs)
    tarball_hash = publish_artifact(repo, tag, hash, filename)

    return [
        ("https://github.com/$(repo)/releases/download/$(tag)/$(filename).tar.gz", tarball_hash),
    ]
end

# Given a name and the unpacked/squashfs hashes, slip this new compiler shard into
# the Artifacts.toml that belongs to BB
function insert_compiler_shard(name, version, hash, archive_type; platform=host_platform, download_info = nothing, target=nothing)
    cs = CompilerShard(name, version, platform, archive_type; target=target)
    artifacts_toml = joinpath(dirname(dirname(pathof(BinaryBuilder))), "Artifacts.toml")
    bind_artifact!(artifacts_toml, BinaryBuilder.artifact_name(cs), hash; platform=platform, download_info=download_info, lazy=true, force=true)
end

function upload_and_insert_shards(repo, name, version, unpacked_hash, squashfs_hash, platform; target=nothing)
    # Upload them both to GH releases on Yggdrasil
    unpacked_dl_info = upload_compiler_shard(repo, name, version, unpacked_hash, :unpacked; platform=platform, target=target)
    squashfs_dl_info = upload_compiler_shard(repo, name, version, squashfs_hash, :squashfs; platform=platform, target=target)

    # Insert these final versions into BB
    insert_compiler_shard(name, version, unpacked_hash, :unpacked; download_info=unpacked_dl_info, platform=platform, target=target)
    insert_compiler_shard(name, version, squashfs_hash, :squashfs; download_info=squashfs_dl_info, platform=platform, target=target)
end

function upload_and_insert_shards(repo, name, version, build_info; target=nothing)
    for platform in keys(build_info)
        unpacked_hash = build_info[platform][3]
        squashfs_hash = unpacked_to_squashfs(unpacked_hash, name, version; platform=platform, target=target)

        upload_and_insert_shards(repo, name, version, unpacked_hash, squashfs_hash, platform; target=target)
    end
end


macro flag(name)
    quote
        if isa($(esc(name)), AbstractString)
            $(esc(name))
        elseif $(esc(name)) === true
            $(string("--", name))
        else
            ""
        end
    end
end
function jrun(script::String, args::String...; verbose=verbose, debug=debug, deploy=false, register=false)
    run(`$(Base.julia_cmd()) --color=yes $(script) $(filter(x -> !isempty(x), [@flag(verbose), @flag(debug), @flag(deploy), @flag(register), args...]))`)
end

import BinaryBuilder: build_tarballs 
function build_tarballs(project_path::String, args::String...; deploy=false, register=false)
    @info("Building $(project_path)...")
    cd(project_path) do
        jrun("build_tarballs.jl", args...; deploy=deploy, register=register)
    end
end


