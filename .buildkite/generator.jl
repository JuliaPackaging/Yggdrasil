#!/bin/env julia
import Pkg

Base.set_active_project(@__DIR__)
using YAML

const PROJECTS = copy(ARGS)
const DEBUG = !haskey(ENV, "BUILDKITE")
const IS_PR = get(ENV, "BUILDKITE_PULL_REQUEST", "false") != "false"
const SKIP_BUILD_COOKIE="[skip build]"

if IS_PR
    # If we're on a PR though, we look at the entire branch at once
    BASE_BRANCH = get(ENV, "BUILDKITE_PULL_REQUEST_BASE_BRANCH", "master")
    @assert !isempty(BASE_BRANCH)

    PR_NUMBER = ENV["BUILDKITE_PULL_REQUEST"]
    run(ignorestatus(`git fetch origin "refs/pull/$(PR_NUMBER)/head:refs/remotes/origin/pr/$(PR_NUMBER)"`))

    COMMIT_MSG = readchomp(`git show -s --format=%B origin/pr/$(PR_NUMBER)`)
else
    COMMIT_MSG = readchomp(`git show -s --format=%B`)
end

# Force ourselves to use the shared depot as well, if it exists
if isdir("/sharedcache/depot")
    push!(Base.DEPOT_PATH, "/sharedcache/depot")
end

# Instantiate, to install all necessary packages like YAML (not BinaryBuilder)
Pkg.instantiate()

include("utils.jl")

# Give a warning if the pkgserver is too far behind
check_pkgserver_latency()

# If there are scary projects we need to exclude, we list them here. (Used to contain `LLVM`)
EXCLUDED_NAMES = Set{String}([])

filter!(PROJECTS) do project
    if project ∈ EXCLUDED_NAMES
        @info("Skipping project since it is excluded.", project)
        return false
    end
    return true
end

# Clear out any old `.meta.json` files in the Yggdrasil root
cleanup_metadata!()

# Immediately read in all projects, and ensure that they are either all BB2 projects, or none of them are:
bb2_projects = String[]
bb1_projects = String[]
for project in PROJECTS
    if uses_bb2(project)
        push!(bb2_projects, project)
    else
        push!(bb1_projects, project)
    end
end

function bb1_build_steps!(group_steps, project)
    # determine the name, removing any trailing version number
    # (`L/LLVM/LLVM@14` results in `NAME = "LLVM"`)
    project_basename = basename(project)

    # We always invoke a `build_tarballs.jl` file from its own directory to generate the platform list
    cd(project) do
        println("[$(project)] Generating meta.json...")
        json_path = "$(YGGDRASIL_BASE)/$(project_basename).meta.json"
        julia(`--compile=min ./build_tarballs.jl --meta-json="$(json_path)"`; julia_project = bb1_julia_project)

        # Generate platforms
        julia(`$(bb1_julia_project)/generate_platforms.jl "$(json_path)" $(YGGDRASIL_BASE)/$(project_basename).platforms.list`)
    end

    platforms = split(readchomp(joinpath(YGGDRASIL_BASE, "$(project_basename).platforms.list")))
    if isempty(platforms)
        @error("Unable to determine the proper platforms", project_basename)
        exit(1)
    end

    should_skip_builds = contains(COMMIT_MSG, SKIP_BUILD_COOKIE)
    steps = []
    for platform in platforms
        if !should_skip_builds
            println("[$(project)] $(platform): building")
            bs = BB1BuildStep(
                project_basename,
                project,
                platform,
            )
            push!(steps, render(bs))
        end
    end

    # If this is not a pull request, we're going to register this project
    if !IS_PR
        push!(steps, wait_step())
        push!(steps, render(BB1RegisterStep(
            project_basename,
            project,
            should_skip_builds,
            length(platforms),
        )))
        #push!(steps, wait_step())
        #push!(steps, register_step(project_name, project, should_skip_builds, length(platforms)))
    end

    # Group this project's full build under `project_name`
    if !isempty(steps)
        push!(group_steps, group_step(project_basename, steps))
    end
end

function bb2_build_steps!(group_steps, projects)
    # Invoke `scheduler.jl` to build up our list of jobs with their dependencies
    io = IOBuffer()
    julia(`$(bb2_julia_project)/scheduler.jl $(projects)`; julia_project=bb2_julia_project, stdout=io)
    groups = YAML.load(String(take!(io)))

    # We will create one group per packaging project, and each build will belong to one of those 
    for (group_name, group) in groups
        builds = []
        steps = []
        for build in group["builds"]
            bs = BB2BuildStep(
                build["name"],
                group_name,
                build["platform"],
                build["build_hash"],
                build["dependencies"],
            )
            push!(builds, bs)
            push!(steps, render(bs))
        end

        for packaging in group["packagings"]
            deps = vcat(
                # Other packages that must be registered
                packaging["dependencies"],
                # Our own builds
                builds,
            )
            rs = BB2RegisterStep(packaging["name"], group_name, deps)
            push!(steps, render(rs))
        end
        push!(group_steps, group_step(group_name, steps))
    end
end


function build_steps!(group_steps, bb1_projects, bb2_projects)
    if !isempty(bb1_projects)
        # Ensure BB1 is instantiated
        julia(`-e "import Pkg; Pkg.instantiate(); Pkg.precompile()"`; julia_project=bb1_julia_project)

        # Each project is processed individually, with a group of builds for each platform.
        for project in bb1_projects
            bb1_build_steps!(group_steps, project)
        end
    end

    if !isempty(bb2_projects)
        # Ensure BB2 is instantiated
        julia(`-e "import Pkg; Pkg.instantiate(); Pkg.precompile()"`; julia_project=bb2_julia_project)

        # For BB2, we jointly process all `build_tarballs.jl` files, building a dependency graph:
        bb2_build_steps!(group_steps, bb2_projects)
    end
end


group_steps = []
build_steps!(group_steps, bb1_projects, bb2_projects)

# Only upload the pipieline if we actually have something to upload
if !isempty(group_steps)
    upload_pipeline(Dict(:steps => group_steps))
end
