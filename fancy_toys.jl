# This is a collection of toys under the Yggdrasil tree for the good <s>kids</s>
# developers.  These utilities can be employed in builder files.

using BinaryBuilder, Pkg, LibGit2, Base.BinaryPlatforms

"""
    should_build_platform(platform) -> Bool

Return whether the tarballs for the given `platform` should be built.

This is useful when the builder has different platform-dependent elements
(sources, script, products, etc...) that make it hard to have a single
`build_tarballs` call.
"""
function should_build_platform(platform)
    # If you need inspiration for how to use this function, look at the builder
    # for Git:
    # https://github.com/JuliaPackaging/Yggdrasil/blob/c3e3c4a96c723306b4da23fc6d05f12995b21ed8/G/Git/build_tarballs.jl#L76-L93

    # Get the list of platforms requested from the command line.  This should be
    # the only argument not prefixed with "--".
    requested_platforms = filter(arg -> !occursin(r"^--.*", arg), ARGS)

    if isone(length(requested_platforms))
        # `requested_platforms` has only one element: the comma-separated list
        # of platform.  We'll run the platform only if it's in the list
        return any(platforms_match.(Ref(platform), split(requested_platforms[1], ",")))
    else
        # `requested_platforms` doesn't have only one element: if its length is
        # zero, no platform has been explicitely passed from the command line
        # and we we'll run all platforms, otherwise we don't know what to do, so
        # let's return false to be safe.
        return iszero(length(requested_platforms))
    end
end

"""
    get_tree_hash(tree::LibGit2.GitTree)

Given a `GitTree`, get the `GitHash` that identifies it.
"""
function get_tree_hash(tree::LibGit2.GitTree)
    oid_ptr = Ref(LibGit2.GitHash())
    oid_ptr = ccall((:git_tree_id, :libgit2), Ptr{LibGit2.GitHash}, (Ptr{Cvoid},), tree.ptr)
    oid_ptr == C_NULL && throw("bad tree ID: $tree")
    return unsafe_load(oid_ptr)
end

"""
    get_addable_spec(name, version)

Given a JLL name and registered version, return a `PackageSpec` that, when passed as a
`Dependency`, ensures that exactly that version will be installed.  Example usage:

    dependencies = [
        BuildDependency(get_addable_spec("LLVM_jll", v"9.0.1+0")),
    ]
"""
function get_addable_spec(name::AbstractString, version::VersionNumber)
    Pkg.Registry.update()
    ctx = Pkg.Types.Context()

    # First, resolve the UUID
    uuid = first(Pkg.Types.registry_resolve!(ctx, Pkg.Types.PackageSpec(name=name))).uuid

    # Next, determine the tree hash from the registry
    tree_hashes = Base.SHA1[]
    paths = Pkg.Operations.registered_paths(ctx, uuid)
    for path in paths
        vers = Pkg.Operations.load_versions(ctx, path; include_yanked = true)
        tree_hash = get(vers, version, nothing)
        tree_hash !== nothing && push!(tree_hashes, tree_hash)
    end

    if isempty(tree_hashes)
        error("Unable to find mapping for $(name) v$(version)")
    end
    tree_hash_sha1 = first(tree_hashes)
    tree_hash_bytes = tree_hash_sha1.bytes

    # Once we have a tree hash, turn that into a git commit sha
    url = "https://github.com/JuliaBinaryWrappers/$(name).jl"
    git_commit_sha = nothing
    mktempdir() do dir
        repo = LibGit2.clone(url, dir)
        LibGit2.with(LibGit2.GitRevWalker(repo)) do walker
            LibGit2.push_head!(walker)
            for oid in walker
                tree = LibGit2.peel(LibGit2.GitTree, LibGit2.GitCommit(repo, oid))
                if all(get_tree_hash(tree).val .== tree_hash_bytes)
                    git_commit_sha = LibGit2.string(oid)
                    break
                end
            end
        end
    end

    if git_commit_sha === nothing
        error("Unable to find corresponding revision in $(name) v$(version) for tree hash $(bytes2hex(tree_hash_bytes))")
    end

    @static if VERSION >= v"1.4"
        repo=Pkg.Types.GitRepo(rev=git_commit_sha, source=url)
    else
        repo=Pkg.Types.GitRepo(rev=git_commit_sha, url=url)
    end
    return Pkg.Types.PackageSpec(
        name=name,
        uuid=uuid,
        version=version,
        tree_hash=tree_hash_sha1,
        repo=repo,
    )
end

"""
    encode_target_platform(target_platform::Platform)

Encode a target as tags within a host platform object.  This allows recipes such as
GCC to provide multiple "target" artifacts, while all still properly identifying themselves
as having a single "host" architecture.
"""
function encode_target_platform(target_platform::Platform;
                                host_platform::Platform = Platform("x86_64", "linux"; libc="musl"))
    error("Don't use this, use `CrossPlatform` instead!")
    p = deepcopy(host_platform)
    for (tag, value) in tags(target_platform)
        p["target_"*tag] = value
    end
    return p
end

"""
    decode_target_triplet(encoded_platform::Platform)

Decode a target from tags within `encoded_platform`.
"""
function decode_target_platform(encoded_platform::Platform)
    target_tags = Dict(k[8:end] => v for (k, v) in tags(encoded_platform) if startswith(k, "target_"))
    arch = pop!(target_tags, "arch")
    os = pop!(target_tags, "os")
    return Platform(arch, os; Dict(Symbol(k) => v for (k, v) in target_tags)...)
end

"""
    bash_parse_encoded_target_triplet()

This generates bash code to parse out an encoded target triplet from 
"""
function bash_parse_encoded_target_triplet()
    return raw"""
    # Figure out target arch from full target triplet
    function parse_platform_tag() {
        tr '-' '\n' <<< "${bb_full_target}" | grep "${1}" | cut -d'+' -f2-
    }
    encoded_arch=$(parse_platform_tag "target_arch")
    encoded_os=$(parse_platform_tag "target_os")
    encoded_libc=$(parse_platform_tag "target_libc")
    encoded_callabi=$(parse_platform_tag "target_callabi")
    if [[ "${encoded_libc}" == "glibc" ]] || [[ "${encoded_os}${encoded_libc}" == "linux" ]]; then
        encoded_libc="gnu"
    fi

    # Re-assemble `encoded_target` according to some simplified target generation rules
    if [[ "${encoded_os}" == "freebsd" ]]; then
        encoded_target="${encoded_arch}-unknown-${encoded_os}"
    elif [[ "${encoded_os}" == "darwin" ]]; then
        encoded_target="${encoded_arch}-apple-${encoded_os}"
    elif [[ "${encoded_os}" == "windows" ]]; then
        encoded_target="${encoded_arch}-w64-mingw32"
    elif [[ "${encoded_os}" == "linux" ]]; then
        encoded_target="${encoded_arch}-${encoded_os}-${encoded_libc}${encoded_callabi}"
    else
        echo "ERROR: Unknown encoded OS '${encoded_os}'!" >&2
        exit 1
    fi
    """
end