import YAML

function upload_pipeline(definition)
    try
        open(`buildkite-agent pipeline upload --no-interpolation`, stdout, write=true) do io
            YAML.write(io, definition)
        end
    catch
        println(stderr, "pipeline upload failed:")
        YAML.write(stderr, definition)
        println(stderr)
        rethrow()
    end
end

function annotate(annotation; context="default", style="info", append=true)
    @assert style in ("success", "info", "warning", "error")
    append = append ? `--append` : ``
    cmd = `buildkite-agent annotate --style $(style) --context $(context) $(append)`
    open(cmd, stdout, write=true) do io
        write(io, annotation)
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
        "version" => "1.12.4",
        "artifacts_size_limit" => string(120 << 30), # 120 GiB
    ),
    "JuliaCI/merge-commit" => nothing
]

env(NAME, PROJECT) = Dict(
    "JULIA_PKG_SERVER" => "us-east.pkg.julialang.org",
    "JULIA_PKG_SERVER_REGISTRY_PREFERENCE" => "eager",
    "JULIA_REGISTRYCI_AUTOMERGE" => "true",
    "NAME" => NAME,
    "PROJECT" => PROJECT,
    "YGGDRASIL" => "true",
)

safe_name(fn::AbstractString) = replace(fn, r"[^A-Za-z0-9_\-:]"=>"-")

wait_step() = Dict(:wait => nothing)
group_step(name, steps) = Dict(:group => name, :steps => steps)

function build_step(NAME, PLATFORM, PROJECT, IS_PR)
    script = raw"""
    .buildkite/build.sh
    """

    build_plugins = plugins()
    build_env = env(NAME, PROJECT)
    merge!(build_env, Dict(
        "PLATFORM" => PLATFORM,
        "BINARYBUILDER_AUTOMATIC_APPLE" => "true",
        "BINARYBUILDER_USE_CCACHE" => "true",
        "BINARYBUILDER_STORAGE_DIR" => "/cache/yggdrasil",
        "BINARYBUILDER_CCACHE_DIR" => "/sharedcache/ccache",
        "BINARYBUILDER_NPROC" => "16", # Limit parallelism somewhat to avoid OOM for LLVM
        "AWS_DEFAULT_REGION" => "us-east-1",
    ))

    Dict(
        :key => "$(safe_name(PROJECT))--$(safe_name(PLATFORM))",
        :label => "build -- $PROJECT -- $PLATFORM",
        :agents => agent(),
        :plugins => build_plugins,
        :timeout_in_minutes => 300,
        :priority => IS_PR ? -2 : -1,
        :concurrency => 12,
        :concurrency_group => "yggdrasil/build/$NAME", # Could use ENV["BUILDKITE_JOB_ID"]
        :commands => [script],
        :env => build_env,
        :artifacts => [
            "**/products/$NAME*.tar.*"
        ],
    )
end

function trigger_registration_step(NAME, PROJECT, SKIP_BUILD, NUM_PLATFORMS)
    register_env = env(NAME, PROJECT)
    # Hand the triggering build's ID to the register pipeline so it can pull the
    # freshly-built tarballs as artifacts from the build that produced them.
    register_env["BUILD_ID"] = get(ENV, "BUILDKITE_BUILD_ID", "")
    if SKIP_BUILD
        register_env["SKIP_BUILD"] = "true"
    end
    # For packages with a large number of platforms, trying to upload several release
    # artifacts at once with `ghr` results in exceeding GitHub's API secondary rate limits.
    # Ref: <https://github.com/JuliaPackaging/BinaryBuilder.jl/pull/1334>.
    if NUM_PLATFORMS > 80
        concurrency = 4
        @info "Reducing ghr concurrency" NAME NUM_PLATFORMS concurrency
        register_env["BINARYBUILDER_GHR_CONCURRENCY"] = string(concurrency)
    end

    # Registration needs the `GITHUB_TOKEN` Buildkite secret, which is only
    # readable from the dedicated `yggdrasil-register` pipeline.  Keeping it out
    # of the build steps (which run potentially untrusted `build_tarballs.jl`
    # code) is the whole point of the split, so rather than registering inline we
    # trigger the `yggdrasil-register` pipeline and hand it everything it needs.
    Dict(
        :label => "trigger registration -- $NAME",
        :trigger => "yggdrasil-register",
        :build => Dict(
            :message => "Register $NAME",
            :commit => ENV["BUILDKITE_COMMIT"],
            :branch => ENV["BUILDKITE_BRANCH"],
            :env => register_env,
        ),
        :async => false, # Wait for the registration to finish
    )
end
