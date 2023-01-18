#!/bin/env julia
if VERSION < v"1.8.0"
    Base.ACTIVE_PROJECT[] = @__DIR__
else
    Base.set_active_project(@__DIR__)
end
import Pkg
Pkg.instantiate()

using Downloads, Dates, SHA

const PROJECT = only(ARGS)
const DEBUG = !haskey(ENV, "BUILDKITE")

include("utils.jl")

if !isnothing(Pkg.pkg_server())
    resp = try
        headers = Pkg.PlatformEngines.get_metadata_headers(Pkg.pkg_server())
        Downloads.request("$(Pkg.pkg_server())/registries"; headers)
    catch e
        # Let us know the download of the registry went wrong, but do not hard fail
        @error "Could not download the registry" exception=(e, catch_backtrace())
    end
    last_mod_idx = findfirst(h -> first(h) == "last-modified", resp.headers)
    msg = "PkgServer: " * resp.url
    delay = if !isnothing(last_mod_idx)
        last_mod = last(resp.headers[last_mod_idx])
        msg *= " -- last updated: " * last_mod
        # Manually strip the "GMT" timezone and hope it never changes.
        # Do not error out if parsing fails.
        dt = tryparse(DateTime, replace(last_mod, " GMT"=>""), dateformat"e, d u y H:M:S")
        # If parsing did fail, set the delay to 0.
        isnothing(dt) ? Second(0) : now(UTC) - dt
    else
        Second(0)
    end
    delay > Second(0) && (msg *= " (" * string(Dates.canonicalize(round(delay, Second))) * " ago)")
    @info(msg)
    annotate(msg, style="info", context="pkg")
    tolerance = Hour(1)
    if delay > tolerance
        @warn "The PkgServer registry is older than $(tolerance)"
        annotate("The PkgServer registry is older than $(tolerance)", style = "warning", context="pkg")
    end
end

# If there are scary projects we need to exclude, we list them here. (Used to contain `LLVM`)
EXCLUDED_NAMES = Set{String}([])

if PROJECT ∈ EXCLUDED_NAMES
    @info "Skipping project since it is excluded." PROJECT
    exit()
end

# Remove secret from environment
sanitize(cmd) = addenv(cmd, Dict("BUILDKITE_PLUGIN_CRYPTIC_BASE64_SIGNED_JOB_ID_SECRET" => nothing))
exec(cmd) = @assert success(pipeline(sanitize(cmd), stderr=stderr, stdout=stdout))

YGGDRASIL_BASE = dirname(@__DIR__)
julia(args) = `$(Base.julia_cmd()) --project=$(YGGDRASIL_BASE)/.ci $args`

# Next, we're going to ensure that our BB is up to date and precompiled
julia(`-e "import Pkg; Pkg.instantiate(); Pkg.precompile()"`) |> exec

# Next, for each project, download its sources. We do this by generating meta.json
# files, then parsing them with `download_sources.jl`

TEMP = mktempdir()

const NAME = basename(PROJECT)

# We always invoke a `build_tarballs.jl` file from its own directory
cd(PROJECT) do
    println("Generating meta.json...")
    JSON_PATH = "$(TEMP)/$(NAME).meta.json"
    julia(`--compile=min ./build_tarballs.jl --meta-json="$(JSON_PATH)"`) |> exec

    println("Downloading sources...")
    julia(`$(YGGDRASIL_BASE)/.ci/download_sources.jl "$(JSON_PATH)" $(TEMP)/$(NAME).platforms.list`) |> exec
end

println("Determining builds to queue...")

# Load in the platforms
PLATFORMS = split(readchomp(joinpath(TEMP, "$(NAME).platforms.list")))
if isempty(PLATFORMS)
    @error "Unable to determine the proper platforms" NAME
end

const IS_PR = get(ENV, "BUILDKITE_PULL_REQUEST", "false") != "false"
const SKIP_BUILD_COOKIE="[skip build]"

if IS_PR
    # If we're on a PR though, we look at the entire branch at once
    BASE_BRANCH = get(ENV, "BUILDKITE_PULL_REQUEST_BASE_BRANCH", "master")
    @assert !isempty(BASE_BRANCH)

    PR_NUMBER = ENV["BUILDKITE_PULL_REQUEST"]
    exec(`git fetch origin "refs/pull/$(PR_NUMBER)/head:refs/remotes/origin/pr/$(PR_NUMBER)"`)

    COMMIT_MSG = readchomp(`git show -s --format=%B origin/pr/$(PR_NUMBER)`)
else
    COMMIT_MSG = readchomp(`git show -s --format=%B`)
end
# This variable will tell us whether we want to skip the build
const SKIP_BUILD = contains(COMMIT_MSG, SKIP_BUILD_COOKIE)

STEPS = Any[]
if !IS_PR
    push!(STEPS, jll_init_step(NAME, PROJECT))
    push!(STEPS, wait_step())
end
# Create the BUILD_STEPS
if SKIP_BUILD
    println("The commit messages contains $(SKIP_BUILD_COOKIE), skipping build")
else
    BUILD_STEPS = Any[]
    for PLATFORM in PLATFORMS
        println("    $(PLATFORM): building")

        push!(BUILD_STEPS, build_step(NAME, PLATFORM, PROJECT))
    end
    push!(STEPS, group_step(NAME, BUILD_STEPS))
end
if !IS_PR
    push!(STEPS, wait_step())
    push!(STEPS, register_step(NAME, PROJECT, SKIP_BUILD))
end

definition = Dict(
    :steps => STEPS
)
upload_pipeline(definition)
