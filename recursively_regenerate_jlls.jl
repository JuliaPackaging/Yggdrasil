#!/usr/bin/env julia

using BinaryBuilder, LibGit2, SHA

function build_tarballs_path(dep_name::String, base::String = @__DIR__)
    # Strip _jll from the end of the dep name, if it has it
    if endswith(dep_name, "_jll")
        dep_name = dep_name[1:end-4]
    end
    return joinpath(base, uppercase(dep_name[1:1]), dep_name, "build_tarballs.jl")
end

build_tarballs = build_tarballs_path(get(Sys.ARGS, 1, ""))

if !isfile(build_tarballs)
    println(stderr, "usage: recursively_regenerate_jlls.jl <jll name>")
    exit(1)
end

function recursively_collect_dependencies(build_tarballs::String, dependencies = Set{String}())
    # Generate meta.json for this script, read it in
    @info("Parsing $(build_tarballs)")
    meta_json = String(read(`$(Base.julia_cmd()) --project=$(Base.active_project()) $(build_tarballs) --meta-json`))
    meta_obj = BinaryBuilder.JSON.parse(meta_json)
    for dep in meta_obj["dependencies"]
        if !(dep["name"] ∈ dependencies)
            dep_build_tarballs = build_tarballs_path(dep["name"])
            if !isfile(dep_build_tarballs)
                @warn("Unable to find build_tarballs.jl file for dependency \"$(dep["name"])\"")
            else
                push!(dependencies, dep["name"])
                recursively_collect_dependencies(dep_build_tarballs, dependencies)
            end
        end
    end
    return dependencies
end

# This borrows heavily from BinaryBuilder.yggdrasil_deploy()
function open_jll_bump_pr(dep_name::String)
    @info("Opening JLL-bumping PR for $(dep_name)")
    gh_auth = BinaryBuilder.github_auth(;allow_anonymous=false)
    fork = BinaryBuilder.GitHub.create_fork("JuliaPackaging/Yggdrasil"; auth=gh_auth)

    mktempdir() do tmp
        repo = LibGit2.clone(BinaryBuilder.get_yggdrasil(), tmp)
        build_tarballs = build_tarballs_path(dep_name, tmp)
        if !isfile(build_tarballs)
            throw(ArgumentError("Invalid dep_name \"$(dep_name)\", no file $(build_tarballs)"))
        end

        # We're going to need to alter the build_tarballs.jl file.
        # We will just add a newline onto the end if it doesn't already
        # have two, otherwise we remove one.
        build_tarballs_content = String(read(build_tarballs))
        if build_tarballs_content[end-1:end] != "\n\n"
            build_tarballs_content = string(build_tarballs_content, "\n")
        else
            build_tarballs_content = build_tarballs_content[1:end-1]
        end

        recipe_hash = bytes2hex(sha256(build_tarballs_content))[end-3:end]
        branch_name = "jllbump/$(dep_name)_$(recipe_hash)"
        LibGit2.branch!(repo, branch_name)

        # Write out the modified build_tarballs.jl file
        open(build_tarballs, "w") do io
            write(build_tarballs, build_tarballs_content)
        end

        # Commit modified build_tarballs.jl file
        LibGit2.add!(repo, build_tarballs_path(dep_name, ""))
        LibGit2.commit(repo, "Bump JLL wrapper: $(dep_name)\n\n[skip build]")
        creds = LibGit2.UserPasswordCredential(
            dirname(fork.full_name),
            deepcopy(gh_auth.token),
        )
        try
            LibGit2.push(
                repo,
                refspecs=["+HEAD:refs/heads/$(branch_name)"],
                remoteurl="https://github.com/$(fork.full_name).git",
                credentials=creds,
                # This doesn't work :rage: instead we use `+HEAD:` at the beginning of our
                # refspec: https://github.com/JuliaLang/julia/issues/23057
                #force=true,
            )
        finally
            Base.shred!(creds)
        end

		params = Dict(
			"base" => "master",
			"head" => "$(dirname(fork.full_name)):$(branch_name)",
			"maintainer_can_modify" => true,
			"title" => "JLL bump: $(dep_name)",
			"body" => """
			This pull request bumps the JLL version of $(dep_name).
			It was generated via the `recursively_regenerate_jlls.jl` script.
			"""
		)
		pr = BinaryBuilder.create_or_update_pull_request("JuliaPackaging/Yggdrasil", params, auth=gh_auth)
        println("https://github.com/$(fork.full_name)/pull/new/$(BinaryBuilder.HTTP.escapeuri(branch_name))?expand=1")
    end
end

deps = recursively_collect_dependencies(build_tarballs)
push!(deps, Sys.ARGS[1])
println("Discovered dependencies:")
println(deps)

if BinaryBuilder.yn_prompt(BinaryBuilder.WizardState(), "Open JLL-bumping PRs?", :y) == :y
	for dep in deps
		open_jll_bump_pr(dep)
	end
end

