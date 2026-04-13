import Downloads, Pkg, YAML
using Dates

function check_pkgserver_latency(; tolerance = Hour(1))
    # Nothing to do if this is empty
    if isnothing(Pkg.pkg_server())
        return
    end

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
    if delay > tolerance
        @warn "The PkgServer registry is older than $(tolerance)"
        annotate("The PkgServer registry is older than $(tolerance)", style = "warning", context="pkg")
    end
end

# Cleanup `.meta.json` or `.platform.list` files from previous BB1 runs
function cleanup_metadata!()
    for (root, _, files) in walkdir(YGGDRASIL_BASE)
        for file in files
            if endswith(file, ".meta.json") || endswith(file, ".platforms.list")
                rm(joinpath(root, file))
            end
        end
    end
end

function upload_pipeline(definition)
    try
        open(`buildkite-agent pipeline upload --no-interpolation`, stdout, write=true) do io
            YAML.write(io, definition)
        end
    catch e
        @error("pipeline upload failed", e)
        YAML.write(stdout, definition)
    end
end

function annotate(annotation; context="default", style="info", append=true)
    @assert style in ("success", "info", "warning", "error")
    append = append ? `--append` : ``
    cmd = `buildkite-agent annotate --style $(style) --context $(context) $(append)`
    try
        open(cmd, stdout, write=true) do io
            write(io, annotation)
        end
    catch err
        @error("Unable to annotate", err)
    end
end

agent() = Dict(
    :queue => "yggdrasil",
    :arch => "x86_64",
    :os => "linux",
    :sandbox_capable => "true"
)

plugins() = Pair{String, Union{Nothing, Dict}}[
    "JuliaCI/julia#v1" => Dict(
        "persist_depot_dirs" => "packages,artifacts,compiled",
        "version" => "1.12.6",
        "artifacts_size_limit" => string(120 << 30), # 120 GiB
    ),
    "JuliaCI/merge-commit" => nothing
]


safe_name(fn::AbstractString) = replace(fn, r"[^A-Za-z0-9_\-:]"=>"-")

wait_step() = Dict(:wait => nothing)
group_step(name, steps) = Dict(:group => name, :steps => steps)

function init_git_config()
    git_config_dir = mktempdir()
    git_config = joinpath(git_config_dir, "config")
    open(git_config, write=true) do io
        println(io, "[user]")
        println(io, "\name = jlbuild")
        println(io, "\temail = juliabuildbot@gmail.com")
    end
    return git_config
end

env() = Dict(
    "JULIA_PKG_SERVER" => "us-east.pkg.julialang.org",
    "JULIA_PKG_SERVER_REGISTRY_PREFERENCE" => "eager",
    "JULIA_REGISTRYCI_AUTOMERGE" => "true",
    "YGGDRASIL" => "true",

    # Store the (global) git config here, seed it with jlbuild values, and tell git to use only it
    "GIT_CONFIG_GLOBAL" => init_git_config(),
    "GIT_CONFIG_NOSYSTEM" => "true",
)

abstract type AbstractStep; end

abstract type AbstractBuildStep <: AbstractStep; end
struct BB1BuildStep <: AbstractBuildStep
    name::String
    project::String
    platform::String
end

bb1_step_key(project_name::String, platform::String) = "$(safe_name(project_name))--$(safe_name(platform))"
step_key(bs::BB1BuildStep) = bb1_step_key(bs.project, bs.platform)

struct BB2BuildStep <: AbstractBuildStep
    name::String
    project::String
    platform::String
    build_hash::String
    dependencies::Vector{String}
end
step_key(bs::BB2BuildStep) = "$(safe_name(bs.project))--$(bs.build_hash[5:13])"
universe_name(bs::BB2BuildStep) = "$(safe_name(bs.project))-$(YGGDRASIL_COMMIT)"

function universe_flag(s)
    # If we're on a PR, deploy to a custom universe on a custom org
    if get(ENV, "BUILDKITE_PULL_REQUEST", "false") != "false"
        "--universe=$(universe_name(s))"
    end
    return ""
end

function render(bs::AbstractBuildStep)
    build_plugins = plugins()

    # On BB1, we pass the platform to build for, on BB2 we identify by build hash
    if isa(bs, BB1BuildStep)
        build_sh_args = "$(bs.platform)"
    else
        build_sh_args = "$(universe_flag(bs)) --build-hashes=$(bs.build_hash) --archive-dir=products"
    end

    build_env = merge(env(), Dict(
        # These are all BinaryBuilder1 specific, but they don't hurt to send to BB2
        "BINARYBUILDER_AUTOMATIC_APPLE" => "true",
        "BINARYBUILDER_USE_CCACHE" => "true",
        "BINARYBUILDER_STORAGE_DIR" => "/cache/yggdrasil",
        "BINARYBUILDER_CCACHE_DIR" => "/sharedcache/ccache",
        "BINARYBUILDER_NPROC" => "16", # Limit parallelism somewhat to avoid OOM for LLVM
        "AWS_DEFAULT_REGION" => "us-east-1",

        # Set the julia project to either the BB1 or BB2 project
        "JULIA_PROJECT" => julia_project(bs),
    ))

    return Dict(
        :key => step_key(bs),
        :label => "build -- $(bs.name) -- $(bs.platform)",
        :agents => agent(),
        :plugins => build_plugins,
        :timeout_in_minutes => 240,
        :priority => -1,
        # Reduce concurrency for Reactant builds, which are extremely intensive and grind
        # the system to a halt when run with several parallel jobs.
        :concurrency => startswith(bs.name, "Reactant") ? 8 : 12,
        :concurrency_group => "yggdrasil/build/$(bs.project)",
        :commands => ["""
        YGGDRASIL_BASE=\$(pwd)
        cd $(bs.project)
        "\${YGGDRASIL_BASE}/.buildkite/build.sh" $(build_sh_args)
        cd "\${YGGDRASIL_BASE}"
        """],
        :env => build_env,
        :artifacts => [
            "$(bs.project)/products/*"
        ]
    )
end

abstract type AbstractRegisterStep <: AbstractStep; end
struct BB1RegisterStep <: AbstractRegisterStep
    name::String
    project::String
    skip_build::Bool
    num_platforms::Int
end

step_key(rs::BB1RegisterStep) = "register-$(rs.name)"

struct BB2RegisterStep <: AbstractRegisterStep
    name::String
    project::String

    dependencies::Vector{AbstractStep}
end
step_key(rs::BB2RegisterStep) = "register-$(rs.name)"
universe_name(rs::BB2RegisterStep) = "$(safe_name(rs.project))-$(YGGDRASIL_COMMIT)"

function render(rs::AbstractRegisterStep)
    register_env = env()
    register_env["NAME"] = rs.name
    register_env["PROJECT"] = rs.project
    register_env["BUILD_ID"] = get(ENV, "BUILDKITE_BUILD_ID", "")
    register_env["JULIA_PROJECT"] = julia_project(rs)
    if isa(rs, BB1RegisterStep)
        if rs.skip_build
            register_env["SKIP_BUILD"] = "true"
        end

        # For packages with a large number of platforms, trying to upload several release
        # artifacts at once with `ghr` results in exceeding GitHub's API secondary rate limits.
        # Ref: <https://github.com/JuliaPackaging/BinaryBuilder.jl/pull/1334>.
        if rs.num_platforms > 80
            concurrency = 4
            @info "Reducing ghr concurrency" rs.name rs.num_platforms concurrency
            register_env["BINARYBUILDER_GHR_CONCURRENCY"] = string(concurrency)
        end
    end

    out = Dict(
        :key => step_key(rs),
        :label => "trigger registration -- $(rs.name)",
        :trigger => "yggdrasil-register",
        :build => Dict(
            :message => "Register $(rs.name)",
            :commit => ENV["BUILDKITE_COMMIT"],
            :branch => ENV["BUILDKITE_BRANCH"],
            :env => register_env,
        ),
        :async => false,
    )

    if isa(rs, BB2RegisterStep)
        out[:depends_on] = step_key.(rs.dependencies)
    end

    return out
end

exec(cmd; stdout=Base.stdout, stderr=Base.stderr) = @assert success(pipeline(cmd; stderr, stdout))

YGGDRASIL_BASE = dirname(@__DIR__)
YGGDRASIL_COMMIT = get(ENV, "BUILDKITE_COMMIT", "1a2b3c")[1:6]
bb1_julia_project = joinpath(YGGDRASIL_BASE, ".ci/bb1_project")
bb2_julia_project = joinpath(YGGDRASIL_BASE, ".ci/bb2_project")
function julia(args; julia_project=bb1_julia_project, stdout = Base.stdout, stderr = Base.stderr)
    return exec(`$(Base.julia_cmd()) --project=$(julia_project) $args`; stdout, stderr)
end

function julia_project(s)
    if isa(s, BB1BuildStep) || isa(s, BB1RegisterStep)
        return ".ci/bb1_project"
    else
        return ".ci/bb2_project"
    end
end

# We will use the BinaryBuilder2 environment if there is a `using BinaryBuilder2` in the build_tarballs.jl file
function uses_bb2(project)
    build_tarballs_path = joinpath(YGGDRASIL_BASE, project, "build_tarballs.jl")
    build_tarballs_contents = String(read(open(build_tarballs_path)))
    return any(startswith.(split(build_tarballs_contents, "\n"), ("using BinaryBuilder2",)))
end
