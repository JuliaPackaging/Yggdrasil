using Pkg
using TOML

const BB2_URL = "https://github.com/JuliaPackaging/BinaryBuilder2.jl.git"

# Name => version of every package that the manifest tracks from a git repository.
function git_tracked_versions(deps::Dict{String,Any})
    return Dict(name => get(entries[1], "version", "")
                for (name, entries) in deps if haskey(entries[1], "repo-url"))
end

# `BinaryBuilder2` lives at the root of its repository, so its `git-tree-sha1` is the root tree
# of a commit on `main`.  Find that commit in a blobless clone of the repository.
function bb2_commit(clone_dir::String, tree_hash::String)
    for line in eachline(`git -C $(clone_dir) log --format='%H %T' origin/main`)
        commit, tree = split(line)
        tree == tree_hash && return String(commit)
    end
    return nothing
end

function main()
    manifest_path = joinpath(@__DIR__, "Manifest.toml")

    old_deps = TOML.parsefile(manifest_path)["deps"]

    Pkg.Registry.update()
    # Resolve the `[sources]` to the current HEAD of their branches and update the registered
    # dependencies, without precompiling.
    withenv("JULIA_PKG_PRECOMPILE_AUTO"=>0) do
        Pkg.update()
    end

    new_deps = TOML.parsefile(manifest_path)["deps"]
    if old_deps == new_deps
        @warn("Dependencies didn't change, exiting...")
        return nothing
    end

    commit_title = "[CI] Update BinaryBuilder2 manifest"
    commit_body = ""

    old_tree = old_deps["BinaryBuilder2"][1]["git-tree-sha1"]
    new_tree = new_deps["BinaryBuilder2"][1]["git-tree-sha1"]
    if old_tree != new_tree
        mktempdir() do clone_dir
            run(`git clone --quiet --bare --filter=blob:none $(BB2_URL) $(clone_dir)`)
            run(`git -C $(clone_dir) fetch --quiet origin '+refs/heads/main:refs/remotes/origin/main'`)
            old_commit = bb2_commit(clone_dir, old_tree)
            new_commit = bb2_commit(clone_dir, new_tree)
            @info "BinaryBuilder2.jl commits" old_commit new_commit
            if old_commit !== nothing && new_commit !== nothing
                commit_body *= "BinaryBuilder2.jl changes: https://github.com/JuliaPackaging/BinaryBuilder2.jl/compare/$(old_commit[1:10])...$(new_commit[1:10])\n\n"
            elseif new_commit !== nothing
                commit_body *= "BinaryBuilder2.jl is now at https://github.com/JuliaPackaging/BinaryBuilder2.jl/commit/$(new_commit)\n\n"
            end
        end
    end

    # List the version changes of the packages tracked from git repositories, since their
    # updates are the ones most likely to affect the builds.
    old_versions = git_tracked_versions(old_deps)
    new_versions = git_tracked_versions(new_deps)
    changed = sort([name for name in keys(new_versions)
                    if get(old_versions, name, nothing) != new_versions[name]])
    if !isempty(changed)
        commit_body *= "Version changes of packages tracked from git:\n"
        for name in changed
            commit_body *= "* $(name): $(get(old_versions, name, "(new)")) -> $(new_versions[name])\n"
        end
    end

    write(ENV["GITHUB_ENV"],
          """
          commit_message<<EOF
          $(commit_title)

          $(commit_body)
          EOF
          commit_title<<EOF
          $(commit_title)
          EOF
          commit_body<<EOF
          $(commit_body)
          EOF
          """)
end

main()
