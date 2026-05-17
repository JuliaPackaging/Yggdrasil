using Pkg
using TOML
using BinaryBuilderBase: get_commit_sha

get_url_tree_hash(dep::Dict{String,Any}) =
    (; url=dep["repo-url"], tree_hash=dep["git-tree-sha1"])

function get_commits(dep_old::T, dep_new::T) where {T<:NamedTuple{(:url, :tree_hash), Tuple{String, String}}}
    if dep_old.url == dep_new.url && dep_old.tree_hash != dep_new.tree_hash
        # Same URL but different tree hashes
        old = get_commit_sha(dep_old.url, Base.SHA1(dep_old.tree_hash); verbose=true)
        new = get_commit_sha(dep_new.url, Base.SHA1(dep_new.tree_hash); verbose=true)
        @info "Git commit hashes for $(basename(dep_old.url))" old new
        (; old, new)
    else
        # Same tree hashes and/or maybe different URLs, but that's a weird case,
        # updating the packages shouldn't change the URL.
        nothing
    end
end

function main()
    manifest_path = joinpath(@__DIR__, "Manifest.toml")

    # Get current versions of BinaryBuilder and BinaryBuilderBase
    old_deps = TOML.parsefile(manifest_path)["deps"]
    bb_old = get_url_tree_hash(old_deps["BinaryBuilder"][1])
    bbb_old = get_url_tree_hash(old_deps["BinaryBuilderBase"][1])

    # Make sure the registry is up-to-date
    Pkg.Registry.update()
    # Update the dependencies, but no need to re-precompile the dependencies
    withenv("JULIA_PKG_PRECOMPILE_AUTO"=>0) do
        Pkg.update()
    end

    new_deps = TOML.parsefile(manifest_path)["deps"]
    if old_deps == new_deps
        # Nothing changed, bye bye
        @warn("Dependencies didn't change, exiting...")
        return nothing
    end

    # Get old and new URLs and commit hashes of BinaryBuilder and BinaryBuilderBase.
    bb_new = get_url_tree_hash(new_deps["BinaryBuilder"][1])
    bbb_new = get_url_tree_hash(new_deps["BinaryBuilderBase"][1])
    bb_commits = get_commits(bb_old, bb_new)
    bbb_commits = get_commits(bbb_old, bbb_new)

    # Commit message
    commit_title = "[CI] Update manifest"
    commit_body = ""
    # Highlight in the commit message the changes in BinaryBuilder and
    # BinaryBuilderBase.
    if bb_commits !== nothing || bbb_commits !== nothing
        commit_body *= "Notable changes:\n"
        if bb_commits !== nothing
            commit_body *= "* https://github.com/JuliaPackaging/BinaryBuilder.jl/compare/$(bb_commits.old)...$(bb_commits.new)\n"
        end
        if bbb_commits !== nothing
            commit_body *= "* https://github.com/JuliaPackaging/BinaryBuilderBase.jl/compare/$(bbb_commits.old)...$(bbb_commits.new)\n"
        end
    end

    # Save environment variables for the next steps
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
