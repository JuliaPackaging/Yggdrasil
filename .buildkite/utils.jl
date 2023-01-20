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
        "version" => "1.7",
        "depot_hard_size_limit" => "68719476736", #64GB
    ),
    "JuliaCI/merge-commit" => nothing
]

env(NAME, PROJECT) = Dict(
    "JULIA_PKG_SERVER" => "us-east.pkg.julialang.org",
    "JULIA_PKG_SERVER_REGISTRY_PREFERENCE" => "eager",
    "NAME" => NAME,
    "PROJECT" => PROJECT,
    "YGGDRASIL" => "true",
    # Inherit the secret so that we can decrypt cryptic secrets
    "BUILDKITE_PLUGIN_CRYPTIC_BASE64_SIGNED_JOB_ID_SECRET" => get(ENV, "BUILDKITE_PLUGIN_CRYPTIC_BASE64_SIGNED_JOB_ID_SECRET", ""),
)

safe_name(fn::AbstractString) = replace(fn, r"[^A-Za-z0-9_\-:]"=>"-")

wait_step() = Dict(:wait => nothing)
group_step(name, steps) = Dict(:group => name, :steps => steps)

function jll_init_step(NAME, PROJECT)
    script = raw"""
    # Don't share secrets with build_tarballs.jl
    BUILDKITE_PLUGIN_CRYPTIC_BASE64_SIGNED_JOB_ID_SECRET="" .buildkite/init.sh
    """

    init_plugins = plugins()
    push!(init_plugins,
        "staticfloat/cryptic#v2" => Dict(
            "variables" => [
                "GITHUB_TOKEN=\"U2FsdGVkX19pZyo9s0+7a8o2ShJ7rk9iDq/27GGmg+tg692sK0ezyqzVDmVfjtUd+NGfVbh+z+Bk3UWf8xwM8Q==\"",
            ]
	  ))

    Dict(
        :label => "jll_init -- $NAME",
        :agents => agent(),
        :plugins => init_plugins,
        :timeout_in_minutes => 10,
        :concurrency => 1,
        :concurrency_group => "yggdrasil/jll_init",
        :commands => [script],
	:env => env(NAME, PROJECT)
    )
end

function build_step(NAME, PLATFORM, PROJECT)
    script = raw"""
    apt-get update
    apt install -y bzip2 p7zip xz-utils unzip zstd
    # Don't share secrets with build_tarballs.jl
    BUILDKITE_PLUGIN_CRYPTIC_BASE64_SIGNED_JOB_ID_SECRET="" AWS_SECRET_ACCESS_KEY="" .buildkite/build.sh
    """

    build_plugins = plugins()
    push!(build_plugins,
        "staticfloat/cryptic#v2" => Dict(
            "variables" => [
                "AWS_SECRET_ACCESS_KEY=\"U2FsdGVkX1846b0BRbZjwIWSFV+Fiv1C/Hds/vB3aTkxubHPnRP6lVxGkAkOcFuvAntkoLF6J64QrOHWvjz8xg==\"",
            ]
        ),
        "staticfloat/coppermind#v2" => Dict(
            "inputs" => [
                PROJECT,
                ".ci/",
                # ?meta.json
            ],
            "s3_prefix" => "s3://julia-bb-buildcache/"
        ),
    )
    build_env = env(NAME, PROJECT)
    merge!(build_env, Dict(
        "PLATFORM" => PLATFORM,
        "BINARYBUILDER_AUTOMATIC_APPLE" => "true",
        "BINARYBUILDER_USE_CCACHE" => "true",
        "BINARYBUILDER_STORAGE_DIR" => "/cache/yggdrasil",
        "BINARYBUILDER_NPROC" => "16", # Limit parallelism somewhat to avoid OOM for LLVM
        "AWS_ACCESS_KEY_ID" => "AKIA4WZGSTHCB2YWWN46",
        "AWS_DEFAULT_REGION" => "us-east-1",
    ))

    Dict(
        :key => "$(safe_name(NAME))--$(safe_name(PLATFORM))",
        :label => "build -- $NAME -- $PLATFORM",
        :agents => agent(),
        :plugins => build_plugins,
        :timeout_in_minutes => 180,
        :priority => -1,
        :concurrency => 16,
        :concurrency_group => "yggdrasil/build/$NAME", # Could use ENV["BUILDKITE_JOB_ID"]
        :commands => [script],
        :env => build_env,
        :artifacts => [
            "**/products/$(first(split(NAME, "@")))*.tar.gz"
        ]
    )
end

function register_step(NAME, PROJECT, SKIP_BUILD)
    script = raw"""
    BUILDKITE_PLUGIN_CRYPTIC_BASE64_SIGNED_JOB_ID_SECRET="" .buildkite/register.sh
    """

    register_plugins = plugins()
    push!(register_plugins,
        "staticfloat/cryptic#v2" => Dict(
            "variables" => [
                "GITHUB_TOKEN=\"U2FsdGVkX19pZyo9s0+7a8o2ShJ7rk9iDq/27GGmg+tg692sK0ezyqzVDmVfjtUd+NGfVbh+z+Bk3UWf8xwM8Q==\"",
            ]
	  ))

    register_env = env(NAME, PROJECT)
    if SKIP_BUILD
        register_env["SKIP_BUILD"] = "true"
    end

    Dict(
        :label => "register -- $NAME",
        :agents => agent(),
        :plugins => register_plugins,
        :timeout_in_minutes => 30,
        :concurrency => 1,
        :concurrency_group => "yggdrasil/register",
        :commands => [script],
	:env => register_env
    )
end
