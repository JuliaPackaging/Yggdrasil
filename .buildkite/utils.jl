import Downloads, Pkg, YAML
using SHA: sha256
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

# Remove a project's metadata files left over from a previous BB1 run.  The generator runs
# once per project in the same checkout, and the launcher uploads the files of every project
# afterwards, so this must not touch the files of other projects.
function cleanup_metadata!(project_basename)
    for ext in (".meta.json", ".platforms.list", ".reuse.json")
        rm(joinpath(YGGDRASIL_BASE, project_basename * ext); force=true)
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
        println()
        rethrow()
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

# The agents' scheduler reserves 4 GiB for an untagged job and kills it beyond 16 GiB.
# Builds of these projects, or of any project under these directories, need more: most peaked at
# 19-45 GiB (2026-11), and LLVM links many large binaries in parallel. They declare it: the
# request is what the scheduler reserves, the limit the job's `memory.max`. A project whose
# builds get OOM-killed belongs in this list.
#
# The request is typical use, not the peak: these builds average 4-8 GiB and 3-10 CPUs, and the
# peaks of concurrent jobs rarely coincide (host memory stayed near half the sum of their peaks).
# Reserving the peak kept jobs queued on agents with hundreds of GiB free.
const LARGE_MEMORY_PROJECTS = [
    "A/AMDGPU_LLVM_Backend",
    "C/cupynumeric",
    "E/Enzyme",
    "L/LLVM",
    "L/LLVMGPU",
    "L/libcxxwrap_julia",
    "L/libigc",
    "L/libpolymake_julia",
    "O/ONNXRuntime/ONNXRuntime_CUDA",
    "O/OpenCV/OpenCV",
    "O/OpenCV/OpenCV_CUDA",
    "V/VTK",
]

is_large_memory(project) =
    any(p -> project == p || startswith(project, p * "/"), LARGE_MEMORY_PROJECTS)

large_memory_agent() = merge(agent(), Dict(
    :sched_cpus => "4",
    :sched_cpus_limit => "16",
    :sched_mem_gib => "12",
    :sched_mem_limit_gib => "64",
))

# BinaryBuilder2 projects are scheduled, built and registered with their own Julia.  It needs
# strict matching of the `sanitize` platform tag (JuliaLang/julia#63647) to resolve JLLs.
const BB1_JULIA_VERSION = "1.13.2"
const BB2_JULIA_VERSION = "1.14.0-alpha2"

plugins(julia_version) = Pair{String, Union{Nothing, Dict}}[
    "JuliaCI/julia#v1" => Dict(
        "persist_depot_dirs" => "packages,artifacts,compiled",
        "version" => julia_version,
        "artifacts_size_limit" => string(120 << 30), # 120 GiB
    ),
    "JuliaCI/merge-commit" => nothing
]


safe_name(fn::AbstractString) = replace(fn, r"[^A-Za-z0-9_\-:]"=>"-")

wait_step() = Dict(:wait => nothing)
group_step(name, steps) = Dict(:group => name, :steps => steps)

function env()
    _env = Dict(
        "JULIA_PKG_SERVER" => "us-east.pkg.julialang.org",
        "JULIA_PKG_SERVER_REGISTRY_PREFERENCE" => "eager",
        "JULIA_REGISTRYCI_AUTOMERGE" => "true",
        "YGGDRASIL" => "true",
        "GIT_CONFIG_NOSYSTEM" => "true",
    )

    # If the scheduler itself has `JULIA_DEBUG` applied,
    # pass it through to build and register steps
    if haskey(ENV, "JULIA_DEBUG")
        _env["JULIA_DEBUG"] = ENV["JULIA_DEBUG"]
    end

    return _env
end

abstract type AbstractStep; end

abstract type AbstractBuildStep <: AbstractStep; end
struct BB1BuildStep <: AbstractBuildStep
    name::String
    project::String
    platform::String
end

# Buildkite rejects keys longer than 100 characters, which platforms with several
# tags (e.g. cross toolchains) can exceed; keep such keys unique with a hash.
function limit_key_length(key::String)
    length(key) <= 100 && return key
    return "$(first(key, 90))-$(bytes2hex(sha256(key))[1:9])"
end

bb1_step_key(project_name::String, platform::String) =
    limit_key_length("$(safe_name(project_name))--$(safe_name(platform))")
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
    # If we're on a PR, build within a named universe
    if get(ENV, "BUILDKITE_PULL_REQUEST", "false") != "false"
        return "--universe=$(universe_name(s))"
    end
    return ""
end

function render(bs::AbstractBuildStep)
    build_plugins = plugins(julia_version(bs))

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
        "BINARYBUILDER_CLONES_DIR" => "/sharedcache/clones",
        "BINARYBUILDER_NPROC" => "16", # Limit parallelism somewhat to avoid OOM for LLVM
        "AWS_DEFAULT_REGION" => "us-east-1",

        # Set the julia project to either the BB1 or BB2 project
        "JULIA_PROJECT_RELATIVE" => julia_project_relative(bs),
    ))

    return Dict(
        :key => step_key(bs),
        :label => "build -- $(bs.name) -- $(bs.platform)",
        :agents => is_large_memory(bs.project) ? large_memory_agent() : agent(),
        :plugins => build_plugins,
        :timeout_in_minutes => 300,
        :priority => IS_PR ? -2 : -1,
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

step_key(rs::BB1RegisterStep) = "register-$(safe_name(rs.project))"

# A BinaryBuilder2 package is registered by a single step, even when several projects
# build it (e.g. `G/Glibc/Glibc@2.17` and `Glibc@2.19` both build `Glibc`).  That step
# registers one version per project, in order, so they stack into one registry PR.
struct BB2RegisterStep <: AbstractRegisterStep
    name::String
    # Projects to register, in ascending order of the version they build
    projects::Vector{String}

    # Build steps, and the step keys of other registrations
    dependencies::Vector{Union{AbstractStep,String}}
end
bb2_register_key(name::AbstractString) = limit_key_length("register-bb2-$(safe_name(name))")
step_key(rs::BB2RegisterStep) = bb2_register_key(rs.name)
step_key(key::String) = key
universe_name(rs::BB2RegisterStep) = "$(safe_name(rs.name))-$(YGGDRASIL_COMMIT)"

function render(rs::AbstractRegisterStep)
    register_env = env()
    register_env["NAME"] = rs.name
    if isa(rs, BB1RegisterStep)
        register_env["PROJECT"] = rs.project
    else
        register_env["PROJECTS"] = join(rs.projects, " ")
    end
    register_env["BUILD_ID"] = get(ENV, "BUILDKITE_BUILD_ID", "")
    register_env["JULIA_PROJECT_RELATIVE"] = julia_project_relative(rs)
    register_env["JULIA_VERSION"] = julia_version(rs)
    if isa(rs, BB1RegisterStep)
        if rs.skip_build
            register_env["SKIP_BUILD"] = "true"
        end

        # Trying to upload too many release artifacts at once with `ghr` results in exceeding
        # GitHub's API secondary rate limits.
        # Ref: <https://github.com/JuliaPackaging/BinaryBuilder.jl/pull/1334>.
        # The registration gate admits three jobs, so cap each upload at four requests.
        concurrency = 4
        @info "Setting ghr concurrency" rs.name concurrency
        register_env["BINARYBUILDER_GHR_CONCURRENCY"] = string(concurrency)
    elseif get(ENV, "BUILDKITE_PULL_REQUEST", "false") != "false"
        # A named universe deploys to `bb2/<universe>` branches and suffixed release tags,
        # keeping PR registrations off the default branches.
        register_env["BB2_UNIVERSE"] = universe_name(rs)
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

# Registers the BinaryBuilder2 packages that a build builds (`projects`, in dependency
# order) into a local universe without deploying them, and uploads their JLLs, with their
# artifacts and a registry for them, as the depot `jll-depot.tar.gz`.  On pull requests,
# this runs the pull request's code, but without any secrets.
struct BB2PackageStep <: AbstractStep
    projects::Vector{String}
    dependencies::Vector{AbstractStep}
end
step_key(::BB2PackageStep) = "package-bb2-jlls"

function render(ps::BB2PackageStep)
    return Dict(
        :key => step_key(ps),
        :label => ":package: package JLLs locally",
        :depends_on => step_key.(ps.dependencies),
        :agents => agent(),
        :plugins => plugins(BB2_JULIA_VERSION),
        :timeout_in_minutes => 90,
        :commands => [".ci/bb2_project/load_check/package_jlls.sh $(join(ps.projects, " "))"],
        :env => env(),
        :artifacts => ["jll-depot.tar.gz"],
    )
end

# Installs JLLs from the depot that `package_key` uploaded on Julia `julia_version`, next
# to a fresh `General`, and loads them and their products: those of `jlls`
# (`<Name>_jll@<version>`) that, with `oldest_only`, have a `julia` compat that allows no
# older Julia (see `oldest_julia()`), otherwise all of them.
struct BB2LoadCheckStep <: AbstractStep
    julia_version::String
    oldest_only::Bool
    jlls::Vector{String}
    package_key::String
end
step_key(ls::BB2LoadCheckStep) = "load-check-bb2-julia-$(safe_name(ls.julia_version))"

function render(ls::BB2LoadCheckStep)
    return Dict(
        :key => step_key(ls),
        :label => ":julia: load JLLs -- Julia $(ls.julia_version)",
        :depends_on => [ls.package_key],
        :agents => agent(),
        :plugins => [
            "JuliaCI/julia#v1" => Dict("version" => ls.julia_version),
        ],
        :timeout_in_minutes => 60,
        :commands => [
            "buildkite-agent artifact download jll-depot.tar.gz . --step $(ls.package_key)",
            ".ci/bb2_project/load_check/load_check.sh jll-depot.tar.gz$(ls.oldest_only ? " --oldest-julia-only" : "") $(join(ls.jlls, " "))",
        ],
        :env => env(),
    )
end

exec(cmd; stdout=Base.stdout, stderr=Base.stderr) = @assert success(pipeline(cmd; stderr, stdout))

YGGDRASIL_BASE = dirname(@__DIR__)
YGGDRASIL_COMMIT = get(ENV, "BUILDKITE_COMMIT", "1a2b3c")[1:6]
bb1_julia_project = joinpath(YGGDRASIL_BASE, ".ci/bb1_project")
bb2_julia_project = joinpath(YGGDRASIL_BASE, ".ci/bb2_project")
function julia(args; julia_project=bb1_julia_project, stdout = Base.stdout, stderr = Base.stderr)
    return exec(`$(Base.julia_cmd()) --project=$(julia_project) $args`; stdout, stderr)
end

# We pass around repo-relative paths here so that we don't get stymied
# by the repository directory changing when running on a different machine
# from the scheduler.
function julia_project_relative(s)
    if isa(s, BB1BuildStep) || isa(s, BB1RegisterStep)
        return ".ci/bb1_project"
    else
        return ".ci/bb2_project"
    end
end

julia_version(s) = isa(s, BB1BuildStep) || isa(s, BB1RegisterStep) ? BB1_JULIA_VERSION : BB2_JULIA_VERSION

# Runs `generator.jl` for the BinaryBuilder2 projects on BinaryBuilder2's Julia, since the build
# hashes that `scheduler.jl` computes depend on the Julia version.
function bb2_schedule_step(projects)
    return Dict(
        :key => "schedule-bb2",
        :label => ":runner: Schedule BinaryBuilder2 builds",
        :agents => agent(),
        :plugins => plugins(BB2_JULIA_VERSION),
        :timeout_in_minutes => 60,
        :commands => ["julia .buildkite/generator.jl $(Base.shell_escape(projects...))"],
        :env => env(),
    )
end

# We will use the BinaryBuilder2 environment if there is a `using BinaryBuilder2` in the build_tarballs.jl file
function uses_bb2(project)
    build_tarballs_path = joinpath(YGGDRASIL_BASE, project, "build_tarballs.jl")
    build_tarballs_contents = String(read(open(build_tarballs_path)))
    return any(startswith.(split(build_tarballs_contents, "\n"), ("using BinaryBuilder2",)))
end
