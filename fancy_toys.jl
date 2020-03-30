# This is a collection of toys under the Yggdrasil tree for the good <s>kids</s>
# developers.  These utilities can be employed in builder files.

using BinaryBuilder, Pkg, LibGit2

"""
    should_build_platform(platform) -> Bool

Return whether the tarballs for the given `platform` should be built.

This is useful when the builder has different platform-dependent elements
(sources, script, products, etc...) that make it hard to have a single
`build_tarballs` call.
"""
function should_build_platform(platform)
    # If you need inspiration for how to use this function, look at the builder
    # for Git.

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

# compatibility for Julia 1.3-
if VERSION < v"1.4"
    Pkg.Types.registry_resolve!(ctx::Pkg.Types.Context, deps) = Pkg.Types.registry_resolve!(ctx.env, deps)
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
    @static if VERSION >= v"1.4"
        paths = Pkg.Operations.registered_paths(ctx, uuid)
    else
        paths = Pkg.Operations.registered_paths(ctx.env, uuid)
    end
    for path in paths
        vers = Pkg.Operations.load_versions(path; include_yanked = true)
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
