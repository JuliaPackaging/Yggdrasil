#!/usr/bin/env julia

using BinaryBuilder, LibGit2, SHA, Pkg, REPL.Terminals, REPL.TerminalMenus
using BinaryBuilder.Wizard: yn_prompt, WizardState

function de_jll(name::String)
    if endswith(name, "_jll")
        name = name[1:end-4]
    end
    return name
end

function build_tarballs_path(dep_name::String, base::String = @__DIR__)
    return joinpath(base, uppercase(dep_name[1:1]), de_jll(dep_name), "build_tarballs.jl")
end

json_objs = Dict()
function get_json_obj(dep_name::String)
    dep_name = de_jll(dep_name)
    if haskey(json_objs, dep_name)
        return json_objs[dep_name]
    end
    build_tarballs = build_tarballs_path(dep_name)
    if !isfile(build_tarballs)
        @warn("Unable to find build_tarballs.jl file for dependency $(repr(dep_name))")
    end
    @info("Parsing $(build_tarballs)")

    # We're going to `include()` the "build_tarballs.jl" function to avoid the overhead of `using BinaryBuilder`
    # every time we launch a new julia process.
    meta_json = tempname()
    m_name = gensym()
    m = Module(m_name)
    Core.eval(m, quote
        using BinaryBuilder
        eval(x) = $(Expr(:core, :eval))($(m_name), x)
        include(x) = $(Expr(:top, :include))($(m_name), x)
        include(mapexpr::Function, x) = $(Expr(:top, :include))(mapexpr, $(m_name), x)
        # Our special overriding build_tarballs() function:
        function build_tarballs_meta_json(cli_args, args...; kwargs...)
            cli_args = vcat(string("--meta-json=", $(meta_json)), cli_args)
            BinaryBuilder.build_tarballs(cli_args, args...; kwargs...)
        end

        # Clear out ARGS from parent module.  :P
        empty!(ARGS)
    end)
    # Be super-sneaky and replace `build_tarballs()` funciton calls with `build_tarballs_meta_json()`
    Base.include(m, build_tarballs) do expr
        if hasproperty(expr, :head) && expr.head == :call && expr.args[1] == :build_tarballs
            expr.args[1] = :build_tarballs_meta_json
        end
        return expr
    end

    json_objs[dep_name] = BinaryBuilder.JSON.parse(String(read(meta_json)))
    BinaryBuilder.cleanup_merged_object!(json_objs[dep_name])
    rm(meta_json; force=true)
    return json_objs[dep_name]
end

function recursively_collect_dependencies(dep_name::String, dependencies = Set{String}())
    # Generate meta.json for this script, read it in
    meta_obj = get_json_obj(dep_name)
    for dep in meta_obj["dependencies"]
        name = BinaryBuilder.BinaryBuilderBase.getname(dep)
        if !(name ∈ dependencies)
            push!(dependencies, name)
            recursively_collect_dependencies(name, dependencies)
        end
    end
    return dependencies
end

function download_binaries_from_release(dep_name, code_dir, download_dir)
    Pkg.PlatformEngines.probe_platform_engines!()

    # Doownload the tarballs reading the information in the current `Artifacts.toml`.
    artifacts = Pkg.Artifacts.load_artifacts_toml(joinpath(code_dir, "Artifacts.toml"))
    artifact_listing = artifacts[dep_name]

    # Deal with non-platform-specific artifacts
    if isa(artifact_listing, Dict)
        artifact_listing = [artifact_listing]
    end

    for artifact in artifact_listing
        info = artifact["download"][1]
        url = info["url"]
        hash = info["sha256"]
        filename = basename(url)
        Pkg.PlatformEngines.download_verify(url, hash, joinpath(download_dir, filename); verbose=true)
    end
end

function regenerate_jll(dep_name::String)
    dep_name = de_jll(dep_name)
    json_obj = get_json_obj(dep_name)
    # From now on we strictly need the name of the package, not the path where
    # the `build_tarballs.jl` is, take the basename so that `FFMPEG/FFMPEG`
    # becomes `FFMPEG`
    dep_name = basename(dep_name)
    code_dir = joinpath(Pkg.devdir(), "$(dep_name)_jll")
    repo = "JuliaBinaryWrappers/$(dep_name)_jll.jl"
    BinaryBuilder.init_jll_package(
        dep_name,
        code_dir,
        repo,
    )

    download_dir = joinpath("/tmp/yggdrasil_download_temp", dep_name)
    mkpath(download_dir)
    download_binaries_from_release(dep_name, code_dir, download_dir)
    build_version = BinaryBuilder.get_next_wrapper_version(json_obj["name"], json_obj["version"])
    tag = "$(json_obj["name"])-v$(build_version)"
    upload_prefix = "https://github.com/$(repo)/releases/download/$(tag)"
    BinaryBuilder.rebuild_jll_package(
        json_obj;
        download_dir=download_dir,
        upload_prefix=upload_prefix,
        verbose=true,
        lazy_artifacts=json_obj["lazy_artifacts"],
        from_scratch=true,
    )
end

# This borrows heavily from BinaryBuilder.yggdrasil_deploy()
function open_jll_bump_pr(dep_name::String)
    @info("Opening JLL-bumping PR for $(dep_name)")
    gh_auth = BinaryBuilder.Wizard.github_auth(;allow_anonymous=false)
    fork = BinaryBuilder.GitHub.create_fork("JuliaPackaging/Yggdrasil"; auth=gh_auth)

    mktempdir() do tmp
        repo = LibGit2.clone(BinaryBuilder.Wizard.get_yggdrasil(), tmp)
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
        pr = BinaryBuilder.Wizard.create_or_update_pull_request("JuliaPackaging/Yggdrasil", params, auth=gh_auth)
        println("https://github.com/$(fork.full_name)/pull/new/$(BinaryBuilder.Wizard.HTTP.escapeuri(branch_name))?expand=1")
    end
end

function recursively_regenerate_jlls(toplevel_dep_name)
    deps = sort!(collect(recursively_collect_dependencies(toplevel_dep_name)))
    push!(deps, toplevel_dep_name)
    sort!(deps)
    terminal = TTYTerminal("xterm", stdin, stdout, stderr)
    selected_deps = request(terminal,
                            "Discovered dependencies:",
                            MultiSelectMenu(deps; selected=eachindex(deps)))
    deps = deps[collect(selected_deps)]
    println("Selected dependencies: $(collect(deps))")

    if yn_prompt(WizardState(), "Open JLL-bumping PRs?", :n) == :y
        for dep in deps
	    open_jll_bump_pr(dep)
        end
    elseif yn_prompt(WizardState(), "Generate new JLLs locally?", :y) == :y
        for dep in deps
            regenerate_jll(dep)
        end
    end
end

if !isfile(build_tarballs_path(get(Sys.ARGS, 1, "")))
    println(stderr, "usage: recursively_regenerate_jlls.jl <jll name>")
    exit(1)
end
recursively_regenerate_jlls(Sys.ARGS[1])
